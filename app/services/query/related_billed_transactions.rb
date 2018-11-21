module Query
  class RelatedBilledTransactions < QueryObject
    def initialize(opts = {})
      @transaction = opts.fetch(:transaction)
    end

    def call
      regime = @transaction.regime
      at = TransactionDetail.arel_table
      q = regime.transaction_details.historic.where.not(id: @transaction.id)
      if regime.installations?
        q = q.where.not(reference_3: nil).
          where.not(reference_3: 'NA').
          where(reference_3: @transaction.reference_3).
          or(q.where.not(reference_1: 'NA').
             where.not(reference_1: nil).
             where(reference_1: @transaction.reference_1)).
          or(q.where.not(reference_2: 'NA').
             where.not(reference_2: nil).
             where(reference_2: @transaction.reference_2))
      else
        q = q.where(reference_1: @transaction.reference_1)
      end
      q.joins(:transaction_file).merge(TransactionFile.order(generated_at: :desc))
    end
  end
end
