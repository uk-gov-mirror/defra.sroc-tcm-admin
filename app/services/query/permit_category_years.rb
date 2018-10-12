module Query
  class PermitCategoryYears < QueryObject
    def initialize(opts = {})
    end

    def call
      # NOTE: doesn't return a query
      %w[ 1819 1920 2021 2122 2223 2324 2425 2526 2627 2728 ].freeze
    end
  end
end
