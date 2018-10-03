# frozen_string_literal: true

class PreSrocRegionsQuery < QueryObject
  def initialize(opts = {})
    @regime = opts.fetch(:regime)
  end
    
  def call
    # NOTE: doesn't return a query
    @regime.transaction_details.retrospective.distinct.pluck(:region).sort
  end
end
