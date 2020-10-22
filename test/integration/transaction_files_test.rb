# frozen_string_literal: true

require "test_helper"

class TransactionFilesTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
  end

  def test_should_have_region_select_filter
    setup_cfd
    visit regime_transaction_files_path(@regime)

    regions = ["All"] + @regime.transaction_headers.distinct.pluck(:region).sort

    assert page.has_select? "region", options: regions
  end

  def test_should_have_pre_post_select_filter_for_cfd
    setup_cfd
    visit regime_transaction_files_path(@regime)
    assert page.has_select? "prepost", options: %w[All Post Pre]
  end

  def test_should_have_pre_post_select_filter_for_pas
    setup_pas
    visit regime_transaction_files_path(@regime)
    assert page.has_select? "prepost", options: %w[All Post Pre]
  end

  def test_should_not_have_pre_post_select_filter_for_waste
    setup_wml
    visit regime_transaction_files_path(@regime)
    assert page.has_no_select? "prepost"
  end
end
