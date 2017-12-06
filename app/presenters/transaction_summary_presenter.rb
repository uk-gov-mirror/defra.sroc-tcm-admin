# frozen_string_literal: true

class TransactionSummaryPresenter < SimpleDelegator
  def summarize(region)
    q = unbilled_transactions.region(region)
    q = regime_specific_group_filter(q)
    credits = q.credits.pluck("charge_calculation -> 'calculation' -> 'chargeValue'")
    invoices = q.invoices.pluck("charge_calculation -> 'calculation' -> 'chargeValue'")
    credit_total = credits.sum
    invoice_total = invoices.sum

    {
      credit_count:   credits.length,
      credit_total:   -credit_total,
      invoice_count:  invoices.length,
      invoice_total:  invoice_total,
      net_total:      invoice_total - credit_total
    }
  end

  def unbilled_transactions
    regime.transaction_details.unbilled
  end

private
  def regime
    __getobj__
  end
end
