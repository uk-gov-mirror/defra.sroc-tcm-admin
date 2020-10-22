# frozen_string_literal: true

require "test_helper"

module Query
  class PreSrocSummaryTest < ActiveSupport::TestCase
    include ActionView::Helpers::NumberHelper

    def setup
      @regime = regimes(:cfd)
      @region = "A"
      @user = users(:billing_admin)
      @regime.transaction_details.update_all(status: "retrospective")
    end

    def test_returns_summary_data
      assert @regime.transaction_details.retrospective.count.positive?
      summary = PreSrocSummary.call(regime: @regime,
                                    region: @region)
      q = @regime.transaction_details.retrospective.region(@region)
      credits = q.credits.pluck(:line_amount)
      invoices = q.invoices.pluck(:line_amount)
      c_tot = credits.sum
      i_tot = invoices.sum

      assert_equal credits.length, summary.credit_count
      assert_equal number_to_currency(c_tot / 100.0), summary.credit_total
      assert_equal invoices.length, summary.invoice_count
      assert_equal number_to_currency(i_tot / 100.0), summary.invoice_total
      assert_equal number_to_currency((c_tot + i_tot) / 100.0), summary.net_total
    end
  end
end
