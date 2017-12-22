class CfdTransactionFilePresenter < SimpleDelegator
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
    transactions = CfdTransactionDetailPresenter.wrap(transaction_details.order(:id))
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
    [
      "D",
      padded_number(idx),
      td.customer_reference,
      fmt_date(td.transaction_date),
      td.transaction_type,
      td.transaction_reference,
      "",
      "GBP",
      td.header_narrative,
      fmt_date(td.transaction_date),
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      padded_number(td.calculated_amount, 3),
      "",
      td.line_area_code,
      td.line_attr_1, # switched with line_description
      td.line_income_stream_code,
      td.line_context_code,
      td.line_description, # switched with line_attr_1
      td.line_attr_3, # was line_attr_2
      td.category,
      td.line_attr_4,
      td.category_description, # was line_attr_5
      td.baseline_charge,
      td.line_attr_9,   # was line_attr_7
      td.line_attr_8,   # temporary cessation
      td.line_attr_9,   # compliance band
      td.line_attr_10,  # compliance adjustment
      td.line_attr_11,  # performance band
      td.line_attr_12,  # performance adjustment
      "",
      "",
      "",
      td.line_quantity,
      td.unit_of_measure,
      padded_number(td.calculated_amount, 3)
    ]
  end

  def trailer
    count = transaction_details.count
    [
      "T",
      padded_number(count + 1),
      padded_number(count + 2),
      invoice_total,
      credit_total
    ]
  end

private
  def transaction_file
    __getobj__
  end

  def padded_number(val, length = 7)
    val.to_s.rjust(length, "0")
  end

  # def file_id
  #   if feeder_source_code == "CFD"
  #     file_sequence_number
  #   else
  #     padded_number(file_sequence_number, 5)
  #   end
  # end

  def record_count
    count = transaction_details.count + 2
    if feeder_source_code == "CFD"
      count
    else
      padded_number(count, 8)
    end
  end

  def feeder_source_code
    regime.name
  end

  def fmt_date(dt)
    dt.strftime("%-d-%^b-%Y")
  end
end
