# frozen_string_literal: true
require 'test_helper.rb'

module Query
  class PermitCategoryLookupTest < ActiveSupport::TestCase
    def setup
      @regime = regimes(:cfd)
      @user = users(:billing_admin)
      @regime.transaction_details.update_all(status: 'excluded')
    end

    def test_returns_permit_categories_active_for_financial_year
      %w[ 1819 1920 2021 2122 2223 2324 2425 2526 2627 2728 ].each do |financial_year|
        categories = PermitCategoryLookup.call(regime: @regime,
                                               financial_year: financial_year)
        expected = @regime.permit_categories.by_financial_year(financial_year).active
        assert_equal expected, categories
      end
    end

    def test_returns_filtered_list_base_on_partial_code
      financial_year = '1819'
      %w[ 2 2.3 2.3.4 6.7.8 ].each do |query|
        categories = PermitCategoryLookup.call(regime: @regime,
                                               financial_year: financial_year,
                                               query: query)
        expected = @regime.permit_categories.by_financial_year(financial_year).active.
          where(PermitCategory.arel_table[:code].matches("%#{query}%"))
        assert_equal expected, categories
      end
    end
  end
end
