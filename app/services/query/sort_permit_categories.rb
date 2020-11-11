# frozen_string_literal: true

module Query
  class SortPermitCategories < QueryObject
    def initialize(opts = {})
      super()
      @query = opts.fetch(:query)
      @sort_column = opts.fetch(:sort, :code)
      @sort_direction = opts.fetch(:sort_direction, "asc")
    end

    def call
      dir = @sort_direction == "desc" ? :desc : :asc
      q = @query

      case @sort_column.to_sym
      when :descripton
        q.order(description: @sort_column)
      else
        q.order(Arel.sql("string_to_array(code, '.')::int[] #{dir}"))
      end
    end
  end
end
