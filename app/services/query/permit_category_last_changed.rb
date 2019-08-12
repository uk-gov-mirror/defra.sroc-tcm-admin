# frozen_string_literal: true
module Query
  class PermitCategoryLastChanged < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
    end

    def call
      @regime.permit_categories.maximum(:updated_at).to_i
    end
  end
end
