require 'test_helper.rb'

module Query
  class TransactionSummaryTest < ActiveSupport::TestCase
    include ActionView::Helpers::NumberHelper, ChargeCalculation

    def setup
      @regime = regimes(:cfd)
      @region = 'A'
      @user = users(:billing_admin)
      Thread.current[:current_user] = @user
      @regime.transaction_details.unbilled.region(@region).each do |transaction|
        v = transaction.line_amount
        transaction.charge_calculation = dummy_charge
        transaction.tcm_charge = v * 23
        transaction.approved_for_billing = true
        transaction.save!
      end
    end

    def test_returns_summary_data
      assert @regime.transaction_details.unbilled.approved.count.positive?, "No transactions"

      summary = Query::TransactionSummary.call(regime: @regime,
                                               region: @region)

      q = @regime.transaction_details.unbilled.region(@region).unexcluded
      credits = q.credits.pluck(:tcm_charge)
      invoices = q.invoices.pluck(:tcm_charge)
      c_tot = credits.sum
      i_tot = invoices.sum

      assert_equal credits.length, summary.credit_count, "Wrong credit count"
      assert_equal number_to_currency(c_tot / 100.0), summary.credit_total, "Wrong credit total"
      assert_equal invoices.length, summary.invoice_count, "Wrong invoice count"
      assert_equal number_to_currency(i_tot / 100.0), summary.invoice_total, "Wrong invoice total"
      assert_equal number_to_currency((c_tot + i_tot) / 100.0), summary.net_total, "Wrong net total"
    end
  end
end
