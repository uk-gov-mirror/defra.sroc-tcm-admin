# frozen_string_literal: true

module Query
  class PermitCategoryLookup < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
      @financial_year = opts.fetch(:financial_year)
      @query = opts.fetch(:query, "")
    end

    def call
      q = @regime.permit_categories.by_financial_year(@financial_year).active
      q = q.where(PermitCategory.arel_table[:code].matches("%#{@query}%")) unless @query.blank?
      SortPermitCategories.call(query: q,
                                sort: "code",
                                sort_direction: "asc")
    end
  end
end
