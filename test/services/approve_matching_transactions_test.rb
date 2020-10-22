# frozen_string_literal: true

require "test_helper"

class ApproveMatchingTransactionsTest < ActiveSupport::TestCase
  include GenerateHistory
  include ChargeCalculation
  include RegimePresenter

  def setup
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
  end

  def test_it_uses_financial_year_when_specified
    t = @regime.transaction_details.unbilled.last
    tt = t.dup
    tt.tcm_financial_year = "1920"
    tt.charge_calculation = dummy_charge
    tt.tcm_charge = 1234
    tt.save!

    result = ApproveMatchingTransactions.call(regime: @regime,
                                              region: tt.region,
                                              financial_year: "1819",
                                              search: "",
                                              user: @user)
    assert result.success?, "Failed to approve"
    refute tt.reload.approved_for_billing?, "Approved but shouldn't be"

    result = ApproveMatchingTransactions.call(regime: @regime,
                                              region: tt.region,
                                              financial_year: "1920",
                                              search: "",
                                              user: @user)
    assert result.success?, "Failed to approve"
    assert tt.reload.approved_for_billing?, "Unapproved but should be"
  end
end
