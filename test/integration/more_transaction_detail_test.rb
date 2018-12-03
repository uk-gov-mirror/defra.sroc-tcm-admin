require 'test_helper'

class MoreTransactionDetailTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def test_absolute_original_permit_shown_for_pas
    setup_pas
    @transaction = transaction_details(:pas)

    visit regime_transaction_path(@regime, @transaction)
    assert_not_nil(@transaction.reference_3, "Blank reference")
    page.assert_selector("dt", text: "Abs Original Permit Ref")
    page.assert_selector("dd", text: @transaction.reference_3)
  end

  def test_retrospective_amount_is_formatted_and_labelled_for_cfd
    setup_cfd
    @transaction = transaction_details(:cfd_retro_invoice_1)
    assert_not_nil @transaction.line_amount, "No line amount"

    amount = ActiveSupport::NumberHelper.number_to_currency(
      sprintf("%.2f", @transaction.line_amount/100.0), unit: "")

    visit regime_transaction_path(@regime, @transaction)
    assert page.has_selector?("dt", text: "Amount (£)"), "Incorrect or missing Amount label"
    assert page.has_selector?("dd", text: amount), "Amount format issue"
  end

  def test_retrospective_amount_is_formatted_and_labelled_for_pas
    setup_pas
    @transaction = transaction_details(:pas_retro_invoice_1)

    assert_not_nil @transaction.line_amount, "No line amount"

    amount = ActiveSupport::NumberHelper.number_to_currency(
      sprintf("%.2f", @transaction.line_amount/100.0), unit: "")

    visit regime_transaction_path(@regime, @transaction)
    assert page.has_selector?("dt", text: "Amount (£)"), "Incorrect or missing Amount label"
    assert page.has_selector?("dd", text: amount), "Amount format issue"
  end

  def test_amount_is_labelled_for_wml
    setup_wml
    @transaction = transaction_details(:wml)

    visit regime_transaction_path(@regime, @transaction)
    assert page.has_selector?("dt", text: "Amount (£)"), "Incorrect or missing Amount label"
  end
end
