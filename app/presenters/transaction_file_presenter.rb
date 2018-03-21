class TransactionFilePresenter < SimpleDelegator
  include FormattingUtils, TransactionGroupFilters

  def header
    [
      "H",
      padded_number(0),
      feeder_source_code,
      region,
      "I",
      file_id,
      "",
      fmt_date(generated_at)
    ]
  end

  def details
    records = []
    transactions = regime_specific_detail_presenter_class.wrap(
      regime_specific_sorter(transaction_details))

    transactions.each.with_index(1) do |td, idx|
      row = detail_row(td, idx)
      if block_given?
        yield row
      else
        records << row
      end
    end
    records
  end

  def detail_row(td, idx)
    raise "Implement me in a subclass"
  end

  def trailer
    count = transaction_details.count
    [
      "T",
      padded_number(count + 1),
      padded_number(count + 2),
      trailer_invoice_total,
      trailer_credit_total
    ]
  end

protected
  def transaction_file
    __getobj__
  end

  def trailer_invoice_total
    transaction_details.where(tcm_transaction_type: 'I').sum(:tcm_charge).to_i
  end

  def trailer_credit_total
    transaction_details.where(tcm_transaction_type: 'C').sum(:tcm_charge).to_i
  end
  
  def file_generated_at
    generated_at.strftime("%d-%^b-%Y")
  end

  def record_count
    count = transaction_details.count + 2
    padded_number(count, 8)
  end

  def feeder_source_code
    regime.name
  end
end
