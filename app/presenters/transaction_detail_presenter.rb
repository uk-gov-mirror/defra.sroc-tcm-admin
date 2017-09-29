class TransactionDetailPresenter < SimpleDelegator

  def self.wrap(collection)
    collection.map { |o| new o }
  end

  def permit_reference
    "todo"
  end

  def sroc_category
    "todo"
  end

  def compliance_band
    "todo"
  end

  def credit_debit_indicator
    line_amount < 0 ? 'C' : 'D'
  end

  def date_received
    fmt_date created_at
  end

  def period
    "todo"
  end

  def amount
    sprintf('%.2f', line_amount / 100.0)
  end

private
  def transaction_detail
    __getobj__
  end

  def padded_number(val, length = 7)
    val.to_s.rjust(length, "0")
  end

  def fmt_date(dt)
    dt.strftime("%-d-%^b-%Y")
  end
end
