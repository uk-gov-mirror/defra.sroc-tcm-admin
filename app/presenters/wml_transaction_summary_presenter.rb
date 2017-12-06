# frozen_string_literal: true

class WmlTransactionSummaryPresenter < TransactionSummaryPresenter
  def regime_specific_group_filter(base_query)
    incomplete_records = base_query.without_charge.distinct.pluck(:reference_1)
    base_query.where.not(reference_1: incomplete_records)
  end
end
