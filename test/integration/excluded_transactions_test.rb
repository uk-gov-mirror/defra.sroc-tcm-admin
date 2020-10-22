# frozen_string_literal: true

require "test_helper"

class ExcludedTransactionsTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def test_style_remains_on_transactions_to_be_billed
    Capybara.current_driver = Capybara.javascript_driver
    # defect 185
    # Open TTBB and ensure any excluded transactions greyed out as expected.
    # Go to Excluded Transactions and search for a customer number or
    # permit/consent ref. Return to TTBB and excluded transactions are no
    # longer greyed out
    setup_cfd
    @transaction = transaction_details(:cfd_unbilled_invoice_1)
    result = ExcludeTransaction.call(transaction: @transaction,
                                     reason: "Trod on false teeth",
                                     user: @user)
    assert result.success?

    @transaction.reload

    visit regime_transactions_path(@regime)
    page.has_selector? "tr.excluded" do |row|
      assert row.has_selector? "td", text: @transaction.reference_1
      assert row.has_style?("color" => "rgba(170, 170, 170, 1)",
                            "text-decoration" => /line-through/)
    end

    page.select "Excluded Transactions", from: "mode"
    page.fill_in "search", with: "wibble"
    page.click_button "Search"

    assert page.has_no_selector? "table tbody tr"

    page.select "Transactions to be billed", from: "mode"
    page.fill_in "search", with: ""
    page.click_button "Search"
    page.has_selector? "tr.excluded" do |row|
      assert row.has_selector? "td", text: @transaction.reference_1
      assert row.has_style?("color" => "rgba(170, 170, 170, 1)",
                            "text-decoration" => /line-through/)
    end
  end
end
