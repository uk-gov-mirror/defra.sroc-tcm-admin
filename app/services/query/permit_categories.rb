module Query
  class PermitCategories < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @financial_year = opts.fetch(:financial_year)
      @search = opts.fetch(:search, '')
      @sort_column = opts.fetch(:sort, :code)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
    end

    def call
      query = @regime.permit_categories.by_financial_year(@financial_year)
      query = query.search(@search) unless @search.blank?
      SortPermitCategories.call(query: query,
                                sort: @sort_column,
                                sort_direction: @sort_direction)
    end
  end
end
