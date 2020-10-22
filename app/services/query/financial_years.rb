# frozen_string_literal: true

module Query
  class FinancialYears < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.transaction_details.distinct.order(:tcm_financial_year).pluck(:tcm_financial_year)
    end
  end
end
