module TransactionGroupFilters
  def grouped_unbilled_transactions_by_region(region)
    regime_specific_group_filter(unbilled_transactions.region(region))
  end

  def unbilled_transactions
    regime.transaction_details.unbilled
  end

  def regime_specific_group_filter(base_query)
    send "#{regime.to_param}_group_filter", base_query
  end

  def cfd_group_filter(base_query)
    incomplete_records = base_query.without_charge.distinct.pluck(:reference_1)
    base_query.where.not(reference_1: incomplete_records)
  end

  def pas_group_filter(base_query)
    incomplete_records = base_query.without_charge.distinct.pluck(:reference_1, :reference_2, :reference_3).transpose

    base_query.where.not(reference_1: incomplete_records[0].reject(&:blank?)).
      where.not(reference_2: incomplete_records[1].reject(&:blank?)).
      where.not(reference_3: incomplete_records[2].reject(&:blank?))
  end

  def wml_group_filter(base_query)
    incomplete_records = base_query.without_charge.distinct.pluck(:reference_1)
    base_query.where.not(reference_1: incomplete_records)
  end
end
