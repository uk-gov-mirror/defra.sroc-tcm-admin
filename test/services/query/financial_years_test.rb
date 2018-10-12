require 'test_helper.rb'

module Query
  class FinancialYearsTest < ActiveSupport::TestCase

    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
    end

    def test_returns_regions
      assert @regime.transaction_details.count.positive?

      regions = FinancialYears.call(regime: @regime)
      expected = @regime.transaction_details.distinct.
        order(:tcm_financial_year).pluck(:tcm_financial_year)
      assert_equal expected, regions
    end
  end
end
