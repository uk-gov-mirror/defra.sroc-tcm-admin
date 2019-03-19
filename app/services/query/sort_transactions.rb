# frozen_string_literal: true
module Query
  class SortTransactions < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime)
      @query = opts.fetch(:query)
      @sort_column = opts.fetch(:sort, :customer_name)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
    end

    def call
      dir = @sort_direction == 'desc' ? :desc : :asc
      q = @query

      # lookup col value
      case @sort_column.to_sym
      when :customer_reference
        q.order(customer_reference: dir, id: dir)
      when :original_filename
        q.order(original_filename: dir, customer_reference: dir)
      when :original_file_date
        q.order(original_file_date: dir, original_filename: dir)
      when :transaction_reference
        q.order(transaction_reference: dir, id: dir)
      when :transaction_date
        q.order(transaction_date: dir, id: dir)
      when :permit_reference
        q.order(reference_1: dir, id: dir)
      when :original_permit_reference
        q.order(reference_2: dir, id: dir)
      when :consent_reference
        q.order(reference_1: dir, reference_2: dir, reference_3: dir, id: dir)
      when :sroc_category
        q.order("string_to_array(category, '.')::int[] #{dir}, id #{dir}")
        # q.order(category: dir, id: dir)
      when :compliance_band
        if @regime.installations?
          q.order(line_attr_11: dir, id: dir)
        else
          q.order(line_attr_6: dir, reference_1: dir)
        end
        # when :variation
        #   q.order(line_attr_9: dir, id: dir)
      when :variation
        q.order("to_number(variation, '999%') #{dir}, id #{dir}")
      when :period
        q.order(period_start: dir, period_end: dir, id: dir)
      when :tcm_transaction_reference
        q.order(tcm_transaction_reference: dir, id: dir)
      when :version
        q.order(reference_2: dir, reference_1: dir)
      when :discharge
        q.order(reference_3: dir, reference_1: dir)
      when :original_filename
        q.order(original_filename: dir, id: dir)
      when :generated_filename
        q.order(generated_filename: dir, id: dir)
      when :generated_file_date
        q.includes(:transaction_file).
          order("transaction_files.created_at #{dir}, tcm_transaction_reference #{dir}")
      when :amount
        q.order(tcm_charge: dir, id: dir)
      when :credit_debit
        q.order(line_amount: dir, id: dir)
      when :excluded_reason
        q.order(excluded_reason: dir, reference_1: dir)
      when :temporary_cessation
        q.order(temporary_cessation: dir, reference_1: dir)
      else
        q.joins(:transaction_header).
          merge(TransactionHeader.order(region: dir, file_sequence_number: dir)).
          order(transaction_reference: dir, id: dir)
      end
    end
  end
end
