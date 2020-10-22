# frozen_string_literal: true

require "test_helper"

class SearchCriteriaPersistenceTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
  end

  def test_sort_column_retained_after_exclusion
    setup_pas
    visit regime_transactions_path(@regime)
    # make Original Permit the sort column
    page.click_link "Original Permit"
    wait_for_ajax
    # sort descending z-a
    page.click_link "Original Permit"
    wait_for_ajax
    # get more details for first row
    page.first(".tcm-table tr.active button.show-details-button").click
    # exclude this transaction
    page.find_button("Exclude from Billing").click
    # choose selected reason and exclude
    page.find_button("Exclude Transaction").click
    # put redirect get
    page.find_button("Reinstate for Billing")
    page.click_link("Back")
    # back to TTBB
    page.click_link("Back")
    assert page.has_selector? "a.sorted.sorted-desc[data-column='original_permit_reference']", text: /Original Permit/
  end
end
