# frozen_string_literal: true

module Query
  class TransactionFileRegions < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
    end

    def call
      # NOTE: doesn't return a query
      @regime.transaction_files.distinct.pluck(:region).sort
    end
  end
end
