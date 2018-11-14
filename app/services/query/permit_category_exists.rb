# frozen_string_literal: true
module Query
  class PermitCategoryExists < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @financial_year = opts.fetch(:financial_year)
      @category = opts.fetch(:category)
    end

    def call
      @regime.permit_categories.by_financial_year(@financial_year).active.
        exists?(code: @category)
    end
  end
end
