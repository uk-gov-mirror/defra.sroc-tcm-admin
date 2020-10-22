# frozen_string_literal: true

module Query
  class RelatedBilledTransactions < QueryObject
    def initialize(opts = {})
      super()
      @transaction = opts.fetch(:transaction)
    end

    def call
      regime = @transaction.regime
      at = TransactionDetail.arel_table
      q = regime.transaction_details.historic.where.not(id: @transaction.id)
      q = if regime.installations?
            q.where.not(reference_3: nil)
             .where.not(reference_3: "NA")
             .where(reference_3: @transaction.reference_3)
             .or(q.where.not(reference_1: "NA")
             .where.not(reference_1: nil)
             .where(reference_1: @transaction.reference_1))
             .or(q.where.not(reference_2: "NA")
             .where.not(reference_2: nil)
             .where(reference_2: @transaction.reference_2))
          elsif regime.water_quality?
            # match consent reference
            q.where(at[:reference_1].matches("#{consent_reference}/%"))
          else
            q.where(reference_1: @transaction.reference_1)
          end
      q.joins(:transaction_file).merge(TransactionFile.order(generated_at: :desc))
    end

    private

    def consent_reference
      m = %r{\A(.*)/(?:\d+)/(?:\d+)\z}.match(@transaction.reference_1)
      if m.nil?
        "invalid reference"
      else
        m[1]
      end
    end
  end
end
