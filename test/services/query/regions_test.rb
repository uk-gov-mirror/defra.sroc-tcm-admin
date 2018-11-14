require 'test_helper.rb'

module Query
  class RegionsTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
    end

    def test_returns_regions
      assert @regime.transaction_details.count.positive?

      regions = Regions.call(regime: @regime)
      expected = @regime.transaction_details.distinct.pluck(:region).sort
      assert_equal expected, regions
    end
  end
end
