require 'test_helper.rb'

module Query
  class BilledFinancialYearsTest < ActiveSupport::TestCase
    include GenerateHistory

    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      generate_historic_cfd
    end

    def test_returns_historic_regions
      assert @regime.transaction_details.historic.count.positive?

      regions = BilledFinancialYears.call(regime: @regime)
      expected = @regime.transaction_details.historic.distinct.
        order(:tcm_financial_year).pluck(:tcm_financial_year)
      assert_equal expected, regions
    end
  end
end
