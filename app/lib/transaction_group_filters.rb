# frozen_string_literal: true

module TransactionGroupFilters
  def regime_specific_detail_presenter_class
    name = "#{regime.slug}_transaction_detail_presenter".camelize
    str_to_class(name) || TransactionDetailPresenter
  end

  def grouped_unbilled_transactions_by_region(region)
    regime_specific_group_filter(unbilled_transactions.region(region).unexcluded)
  end

  def grouped_retrospective_transactions_by_region(region)
    regime_specific_retrospective_sorter(retrospective_transactions.region(region))
  end

  def retrospective_transactions_by_region(region)
    retrospective_transactions.region(region)
  end

  def excluded_transactions_by_region(region)
    excluded_transactions.region(region)
  end

  def unbilled_transactions
    regime.transaction_details.unbilled
  end

  def retrospective_transactions
    regime.transaction_details.retrospective
  end

  def excluded_transactions
    regime.transaction_details.excluded
  end

  def regime_specific_group_filter(base_query)
    send "#{regime.to_param}_group_filter", base_query
  end

  def regime_specific_retrospective_sorter(base_query)
    send "#{regime.to_param}_sorter", base_query
  end

  def regime_specific_sorter(base_query)
    send "#{regime.to_param}_sorter", base_query
  end

  def cfd_group_filter(base_query)
    incomplete_records = base_query.unapproved.distinct.pluck(:reference_1)
    return base_query.approved if incomplete_records.empty?

    base_query.approved.where.not(reference_1: incomplete_records)
  end

  def cfd_sorter(base_query)
    base_query.order(tcm_transaction_reference: :asc,
                     reference_1: :asc,
                     line_amount: :asc)
  end

  def pas_group_filter(base_query)
    incomplete_records = base_query.unapproved.distinct.pluck(:reference_1, :reference_2, :reference_3).transpose

    return base_query.approved if incomplete_records.empty? ||
                                  incomplete_records.flatten.reject(&:nil?).empty?

    base_query.approved
              .where.not(reference_1: incomplete_records[0].reject(&:blank?))
              .where.not(reference_2: incomplete_records[1].reject(&:blank?))
              .where.not(reference_3: incomplete_records[2].reject(&:blank?))
  end

  def pas_sorter(base_query)
    base_query.order(tcm_transaction_reference: :asc,
                     reference_1: :asc,
                     line_amount: :asc)
  end

  def wml_group_filter(base_query)
    incomplete_records = base_query.unapproved.distinct.pluck(:reference_1)
    return base_query.approved if incomplete_records.empty?

    base_query.approved.where.not(reference_1: incomplete_records)
  end

  def wml_sorter(base_query)
    # TODO: make this WML specific
    base_query.order(tcm_transaction_reference: :asc,
                     reference_1: :asc,
                     line_amount: :asc)
  end

  def str_to_class(name)
    name.constantize
  rescue NameError
    nil
  end
end
