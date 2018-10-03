class TransactionsToBeBilledQuery < QueryObject
  def initialize(params)
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
    @sort_column = params.fetch(:sort_column)
    @sort_direction = params.fetch(:sort_direction)
    @search = params.fetch(:search, '')
  end

  def call
    q = @regime.transaction_details.region(@region).unbilled
    q = q.search(@search) unless @search.blank?
    SortTransactionsQuery.call(regime: @regime,
                               query: q,
                               sort_column: @sort_column,
                               sort_direction: @sort_direction)
  end
end
