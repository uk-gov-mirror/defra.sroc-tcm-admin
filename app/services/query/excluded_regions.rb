module Query
  class ExcludedRegions < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.transaction_details.excluded.distinct.pluck(:region).sort
    end
  end
end
