# frozen_string_literal: true

module Query
  class PreSrocRegions < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.transaction_details.retrospective.distinct.pluck(:region).sort
    end
  end
end
