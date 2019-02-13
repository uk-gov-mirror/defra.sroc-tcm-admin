module Query
  class TransactionFiles < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, '')
      @prepost = opts.fetch(:prepost, '')
      @sort_column = opts.fetch(:sort, :file_reference)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
      @search = opts.fetch(:search, '')
    end

    def call
      q = @regime.transaction_files
      q = pre_or_post_sroc(q) unless @prepost.blank? || @prepost == 'all'
      q = q.where(region: @region) unless @region.blank? || @region == 'all'
      q = q.search(@search) unless @search.blank?
      sort_transactions_files(q)
    end

    private

    def pre_or_post_sroc(q)
      if @prepost == 'pre'
        q.pre_sroc
      else
        q.post_sroc
      end
    end

    def sort_transactions_files(q)
      dir = @sort_direction
      case @sort_column.to_sym
      when :generated_at
        q.order(generated_at: dir, id: dir)
      when :generated_by
        q.order(generated_at: dir, id: dir)
      when :credit_count
        q.order(credit_count: dir, id: dir)
      when :credit_total
        q.order(credit_total: dir, id: dir)
      when :debit_count
        q.order(debit_count: dir, id: dir)
      when :invoice_total
        q.order(invoice_total: dir, id: dir)
      when :net_total
        q.order(net_total: dir, id: dir)
      else
        q.order(file_reference: dir, id: dir)
      end
    end
  end
end
