module Query
  class ImportedTransactionFiles < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, '')
      @status = opts.fetch(:status, '')
      @sort_column = opts.fetch(:sort, :file_reference)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
      @search = opts.fetch(:search, '')
    end

    def call
      q = @regime.transaction_headers
      q = q.where(region: @region) unless @region.blank? || @region == 'all'
      q = for_status(q)
      q = q.search(@search) unless @search.blank?
      sort_query(q)
    end

    private

    def for_status(q)
      case @status
      when 'removed'
        q.where(removed: true)
      when 'included'
        q.where(removed: false)
      else
        q
      end
    end

    def sort_query(q)
      dir = @sort_direction
      case @sort_column.to_sym
      when :generated_at
        q.order(generated_at: dir, id: dir)
      when :created_at
        q.order(created_at: dir, id: dir)
      when :credit_count
        q.order(credit_count: dir, id: dir)
      when :credit_total
        q.order(credit_total: dir, id: dir)
      when :invoice_total
        q.order(invoice_total: dir, id: dir)
      else
        q.order(file_reference: dir, id: dir)
      end
    end
  end
end
