class PreSrocFinancialYearsQuery < QueryObject
  def initialize(opts = {})
    @regime = opts.fetch(:regime)
  end
    
  def call
    # NOTE: doesn't return a query
    @regime.transaction_details.retrospective.distinct.order(:tcm_financial_year).
      pluck(:tcm_financial_year)
  end
end
