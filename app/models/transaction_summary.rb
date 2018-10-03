class TransactionSummary
  include ActiveModel::AttributeAssignment, ActionView::Helpers::NumberHelper

  attr_accessor(
    :title,
    :credit_count,
    :credit_total,
    :invoice_count,
    :invoice_total,
    :net_total,
    :excluded_count
  )

  def initialize(regime)
    @regime = regime
  end

  def credit_total
    number_to_currency(@credit_total / 100.0)
  end

  def invoice_total
    number_to_currency(@invoice_total / 100.0)
  end

  def net_total
    number_to_currency(@net_total / 100.0)
  end

  def has_transactions_to_bill?
    credit_count.positive? || invoice_count.positive?
  end
end
