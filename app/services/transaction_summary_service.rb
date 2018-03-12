# frozen_string_literal: true

class TransactionSummaryService
  include TransactionGroupFilters

  attr_reader :user, :regime

  def initialize(regime, user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @regime = regime
    @user = user
  end

  def summarize(region)
    q = grouped_unbilled_transactions_by_region(region)
    package_summary(q, :tcm_charge)
  end

  def summarize_retrospectives(region)
    q = retrospective_transactions_by_region(region)
    package_summary(q, :line_amount)
  end

private
  def package_summary(query, charge_field)
    credits = query.credits.pluck(charge_field)
    invoices = query.invoices.pluck(charge_field)
    credit_total = credits.sum
    invoice_total = invoices.sum

    {
      credit_count:   credits.length,
      credit_total:   credit_total,
      invoice_count:  invoices.length,
      invoice_total:  invoice_total,
      net_total:      invoice_total + credit_total
    }
  end
end
