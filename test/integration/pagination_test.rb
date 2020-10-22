# frozen_string_literal: true

require "test_helper"

class PaginationTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
  end

  def test_can_navigate_to_last_page_on_ttbb
    setup_cfd
    count = 27 - @regime.transaction_details.region("A").unbilled.count
    bulk_up_transaction(:cfd_unbilled_invoice_2, count)
    go_to_last_page(regime_transactions_path(@regime, region: "A",
                                                      page: 1, per_page: 5))
  end

  def test_can_navigate_to_last_page_on_history
    setup_cfd
    count = 27 - @regime.transaction_details.historic.count
    bulk_up_transaction(:cfd_billed_invoice_2, count)
    go_to_last_page(regime_history_index_path(@regime, page: 1, per_page: 5))
  end

  def test_can_navigate_to_last_page_on_retrospectives
    setup_cfd
    count = 27 - @regime.transaction_details.retrospective.count
    bulk_up_transaction(:cfd_retro_invoice_2, count)
    go_to_last_page(regime_retrospectives_path(@regime, page: 1, per_page: 5))
  end

  def test_can_navigate_to_last_page_on_exclusions
    setup_cfd
    count = 27 - @regime.transaction_details.historic_excluded.count
    bulk_up_transaction(:cfd_excluded_invoice_1, count)
    go_to_last_page(regime_exclusions_path(@regime, page: 1, per_page: 5))
  end

  def test_handle_page_too_big_for_ttbb
    setup_cfd
    visit regime_transactions_path(@regime, page: 10, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_small_for_ttbb
    setup_cfd
    visit regime_transactions_path(@regime, page: -13, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_big_for_history
    setup_cfd
    visit regime_history_index_path(@regime, page: 10, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_small_for_history
    setup_cfd
    visit regime_history_index_path(@regime, page: -110, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_big_for_retrospectives
    setup_cfd
    visit regime_retrospectives_path(@regime, page: 10, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_small_for_retrospectives
    setup_cfd
    visit regime_retrospectives_path(@regime, page: -1000, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_big_for_exclusions
    setup_cfd
    visit regime_exclusions_path(@regime, page: 10, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def test_handle_page_too_small_for_exclusions
    setup_cfd
    visit regime_exclusions_path(@regime, page: 0, per_page: 20)
    assert page.has_selector? "div.tcm-table[data-page='1']"
  end

  def go_to_last_page(path)
    visit path
    el = page.find "a.page-link", text: "Last"
    page_num = el["data-page"]
    assert_not_nil page_num, "No last page number"
    assert page_num.to_i > 1
    el.click
    wait_for_ajax
    assert page.has_selector? ".tcm-table[data-page='#{page_num}']"
  end

  def bulk_up_transaction(id, count)
    t = transaction_details(id.to_sym)
    count.times do |_n|
      tt = t.dup
      tt.save!
    end
  end
end
