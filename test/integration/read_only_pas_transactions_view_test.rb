# frozen_string_literal: true

require "test_helper"

class ReadOnlyPasTransactionsViewTest < ActionDispatch::IntegrationTest
  include ChargeCalculation
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    setup_pas_read_only
  end

  def test_no_generate_button
    visit regime_transactions_path(@regime)
    assert page.has_no_button?("Generate Transaction File")
  end

  def test_no_approve_all_button
    visit regime_transactions_path(@regime)
    assert page.has_no_button?("Approve All")
  end

  def test_category_is_read_only
    visit regime_transactions_path(@regime)
    t = page.find("div.tcm-table table tbody")
    assert t.has_selector?("tr.active", minimum: 1), "No rows to test"
    assert t.has_no_selector?("div.tcm-select"), "Category selector found"
  end

  def test_temporary_cessation_is_read_only
    visit regime_transactions_path(@regime)
    t = page.find("div.tcm-table table tbody")
    assert t.has_selector?("tr.active", minimum: 1), "No rows to test"
    assert t.has_no_selector?("select.temporary-cessation-select"),
           "Temporary Cessation selector found"
  end

  def test_approval_flag_is_read_only
    # only see approval slag checkbox when a charge has been generated
    build_mock_calculator
    admin_user = users(:pas_billing_admin)
    Thread.current[:current_user] = admin_user
    transactions = Query::TransactionsToBeBilled.call(regime: @regime)
    assert transactions.count.positive?, "No transactions"
    transactions.each do |transaction|
      assert UpdateCategory.call(transaction: transaction,
                                 category: "2.4.4",
                                 user: admin_user).success?
    end
    Thread.current[:current_user] = @user

    visit regime_transactions_path(@regime)
    t = page.find("div.tcm-table table tbody")
    assert t.has_selector?("tr.active", minimum: 1), "No rows to test"
    assert t.has_no_selector?("input.approve-button"), "Approve button found"
  end

  def test_no_csv_export_button
    visit regime_transactions_path(@regime)
    assert page.has_no_selector?("button.table-export-btn"),
           "CSV export button found"
  end
end
