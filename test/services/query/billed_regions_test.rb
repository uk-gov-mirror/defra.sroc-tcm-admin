require 'test_helper.rb'

module Query
  class BilledRegionsTest < ActiveSupport::TestCase
    include GenerateHistory

    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      generate_historic_cfd
    end

    def test_returns_historic_regions
      assert @regime.transaction_details.historic.count.positive?

      regions = BilledRegions.call(regime: @regime)
      expected = @regime.transaction_details.historic.distinct.pluck(:region).sort
      assert_equal expected, regions
    end
  end
end

