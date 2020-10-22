# frozen_string_literal: true

class TransactionSummary
  include ActionView::Helpers::NumberHelper
  include ActiveModel::AttributeAssignment

  attr_writer :credit_total, :invoice_total, :net_total
  attr_accessor :title, :credit_count, :invoice_count, :excluded_count, :path

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

  def transactions_to_bill?
    credit_count.positive? || invoice_count.positive?
  end
end
