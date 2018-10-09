require 'test_helper.rb'

module Query
  class BilledFinancialYearsTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      @regime.transaction_details.update_all(status: 'excluded')
    end

    def test_returns_historic_regions
      assert @regime.transaction_details.historic_excluded.count.positive?

      regions = ExcludedFinancialYears.call(regime: @regime)
      expected = @regime.transaction_details.historic_excluded.distinct.
        order(:tcm_financial_year).pluck(:tcm_financial_year)
      assert_equal expected, regions
    end
  end
end
