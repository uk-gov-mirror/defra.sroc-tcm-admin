# frozen_string_literal: true

module Query
  class TransactionFiles < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime)
      @region = opts.fetch(:region, "")
      @prepost = opts.fetch(:prepost, "")
      @sort_column = opts.fetch(:sort, :file_reference)
      @sort_direction = opts.fetch(:sort_direction, "asc")
      @search = opts.fetch(:search, "")
    end

    def call
      q = @regime.transaction_files
      q = pre_or_post_sroc(q) unless @prepost.blank? || @prepost == "all"
      q = q.where(region: @region) unless @region.blank? || @region == "all"
      q = q.search(@search) unless @search.blank?
      sort_transactions_files(q)
    end

    private

    def pre_or_post_sroc(query)
      if @prepost == "pre"
        query.pre_sroc
      else
        query.post_sroc
      end
    end

    def sort_transactions_files(query)
      dir = @sort_direction
      case @sort_column.to_sym
      when :generated_at
        query.order(generated_at: dir, id: dir)
      when :generated_by
        query.joins(:user).merge(User.order(first_name: dir, last_name: dir)).order(:id)
      when :credit_count
        query.order(credit_count: dir, id: dir)
      when :credit_total
        query.order(credit_total: dir, id: dir)
      when :debit_count
        query.order(debit_count: dir, id: dir)
      when :invoice_total
        query.order(invoice_total: dir, id: dir)
      when :net_total
        query.order(net_total: dir, id: dir)
      else
        query.order(file_reference: dir, id: dir)
      end
    end
  end
end
