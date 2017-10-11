class TransactionDetailPresenter < SimpleDelegator

  def self.wrap(collection)
    collection.map { |o| new o }
  end

  def file_reference
    transaction_detail.transaction_header.file_reference
  end

  def permit_reference
    "todo"
  end

  def sroc_category
    case category
    when '1'
      'Category 1'
    when '2'
      'Category 2'
    else
      ''
    end
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

  def temporary_cessation_flag
    temporary_cessation? ? 'Y' : 'N'
  end

  def period
    "todo"
  end

  def amount
    if transaction_detail.calculated_charge
      ActiveSupport::NumberHelper.number_to_currency(
        sprintf('%.2f', calculated_charge / 100.0), unit: "")
    else
      if line_amount.negative?
        'Credit (TBC)'
      else
        'Invoice (TBC)'
      end
    end
  end

  def generated_at
    # TODO: replace this with the date *we* generated the file
    fmt_date transaction_detail.transaction_header.generated_at
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
