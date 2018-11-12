module Query
  class TransactionsToBeBilled < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, '')
      @sort_column = opts.fetch(:sort, :customer_reference)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
      @financial_year = opts.fetch(:financial_year, '')
      @search = opts.fetch(:search, '')
    end

    def call
      q = @regime.transaction_details.unbilled
      q = q.region(@region) unless @region.blank? || @region == 'all'
      q = q.financial_year(@financial_year) unless @financial_year.blank?
      q = q.search(@search) unless @search.blank?
      SortTransactions.call(regime: @regime,
                            query: q,
                            sort: @sort_column,
                            sort_direction: @sort_direction)
    end
  end
end
