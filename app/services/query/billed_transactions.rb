# frozen_string_literal: true

module Query
  class BilledTransactions < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, "")
      @search = opts.fetch(:search, "")
      @financial_year = opts.fetch(:financial_year, "")
      @sort_column = opts.fetch(:sort, :customer_reference)
      @sort_direction = opts.fetch(:sort_direction, "asc")
    end

    def call
      query = @regime.transaction_details.historic
      query = query.region(@region) unless @region.blank? || @region == "all"
      query = query.financial_year(@financial_year) unless @financial_year.blank?
      query = query.history_search(@search) unless @search.blank?
      SortTransactions.call(regime: @regime,
                            query: query,
                            sort: @sort_column,
                            sort_direction: @sort_direction)
    end
  end
end
