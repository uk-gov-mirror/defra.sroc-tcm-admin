module Query
  class BilledRegions < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.transaction_details.historic.distinct.pluck(:region).sort
    end
  end
end
