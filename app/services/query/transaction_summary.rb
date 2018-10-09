module Query
  class TransactionSummary < QueryObject
    include TransactionGroupFilters

    def initialize(params = {})
      @regime = params.fetch(:regime)
      @region = params.fetch(:region)
    end

    def call
      q = grouped_unbilled_transactions_by_region(@region)
      excluded = @regime.transaction_details.region(@region).unbilled_exclusions
      package_summary(q, :tcm_charge, excluded)
    end

    private
    def package_summary(query, charge_field, excluded_query = nil)
      credits = query.credits.pluck(charge_field)
      invoices = query.invoices.pluck(charge_field)
      credit_total = credits.sum
      invoice_total = invoices.sum
      excluded_count = excluded_query ? excluded_query.count : 0

      summary = TransactionSummary.new(@regime)
      summary.assign_attributes(
        credit_count:   credits.length,
        credit_total:   credit_total,
        invoice_count:  invoices.length,
        invoice_total:  invoice_total,
        net_total:      invoice_total + credit_total,
        excluded_count: excluded_count
      )
      summary
    end

    # for group filters
    def regime
      @regime
    end
  end
end
