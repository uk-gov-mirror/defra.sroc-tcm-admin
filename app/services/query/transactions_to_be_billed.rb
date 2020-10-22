# frozen_string_literal: true

module Query
  class TransactionsToBeBilled < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, "")
      @unapproved = opts.fetch(:unapproved, false)
      @sort_column = opts.fetch(:sort, :customer_reference)
      @sort_direction = opts.fetch(:sort_direction, "asc")
      @financial_year = opts.fetch(:financial_year, "")
      @search = opts.fetch(:search, "")
    end

    def call
      q = @regime.transaction_details.unbilled
      q = q.region(@region) unless @region.blank? || @region == "all"
      q = q.financial_year(@financial_year) unless @financial_year.blank?
      q = q.unapproved if @unapproved
      q = q.search(@search) unless @search.blank?
      q = q.includes(:suggested_category)
      SortTransactions.call(regime: @regime,
                            query: q,
                            sort: @sort_column,
                            sort_direction: @sort_direction)
    end
  end
end
