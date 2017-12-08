# frozen_string_literal: true

class PasTransactionSummaryPresenter < TransactionSummaryPresenter
  def regime_specific_group_filter(base_query)
    incomplete_records = base_query.without_charge.distinct.pluck(:reference_1, :reference_2, :reference_3)
    ref_1_records = []
    ref_2_records = []
    ref_3_records = []
    incomplete_records.each do |arr|
      ref_1_records << arr[0] unless arr[0].nil?
      ref_2_records << arr[1] unless arr[1].nil?
      ref_3_records << arr[2] unless arr[2].nil?
    end
    base_query.where.not(reference_1: ref_1_records).
      where.not(reference_2: ref_2_records).
      where.not(reference_3: ref_3_records)
  end
end
