require 'test_helper'

class PasTransactionDetailTest < ActionDispatch::IntegrationTest
  def setup
    @regime = regimes(:pas)
    @user = users(:pas_billing_admin)
    @transaction = transaction_details(:pas)
    sign_in @user
  end

  def test_absolute_original_permit_shown
    visit regime_transaction_path(@regime, @transaction)
    assert_not_nil(@transaction.reference_3, "Blank reference")
    page.assert_selector("dt", text: "Abs Original Permit Ref")
    page.assert_selector("dd", text: @transaction.reference_3)
  end
end
