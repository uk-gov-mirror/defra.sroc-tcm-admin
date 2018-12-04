require 'test_helper'

class PaginationTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
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
end
