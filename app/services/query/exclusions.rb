module Query
  class Exclusions < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.exclusion_reasons.order(:reason).pluck(:reason)
    end
  end
end

