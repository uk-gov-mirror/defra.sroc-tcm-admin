class TransactionFileYearsQuery < QueryObject

  def initialize(params = {})
    @transaction_file = params.fetch(:transaction_file)
  end

  def call
    # NOTE: not a query returned
    @transaction_file.transaction_details.distinct.pluck(:tcm_financial_year).sort
  end
end
