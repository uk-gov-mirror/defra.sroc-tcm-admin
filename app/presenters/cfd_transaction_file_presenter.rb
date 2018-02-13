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
      td.file_transaction_date,
      td.tcm_transaction_type,
      td.tcm_transaction_reference,
      "",
      "GBP",
      "",                     # header_narrative always blank
      td.file_transaction_date,  # header_attr_1
      "",                     # header_attr_2
      "",                     # header_attr_3
      "",                     # header_attr_4
      "",                     # header_attr_5
      "",                     # header_attr_6
      "",                     # header_attr_7
      "",                     # header_attr_8
      "",                     # header_attr_9
      "",                     # header_attr_10
      padded_number(td.tcm_charge, 3),  # line_amount
      "",                     # line VAT code always blank
      td.line_area_code,
      "Discharge Location: " + td.line_attr_1, # line_description
      "CT",                   # line income stream code
      td.line_context_code,
      td.line_description,    # line_attr_1
      td.line_attr_3,         # line_attr_2
      td.category,            # line_attr_3
      td.line_attr_4,
      td.category_description, # was line_attr_5
      td.baseline_charge,     # line_attr_6
      td.line_attr_9,         # line_attr_7 (compliance band)
      td.temporary_cessation_file, # temporary cessation
      "",                     # line_attr_9   future - compliance band
      "",                     # line_attr_10  future - compliance adjustment
      "",                     # line_attr_11  future - performance band
      "",                     # line_attr_12  future - performance adjustment
      "",                     # line_attr_13
      "",                     # line_attr_14
      "",                     # line_attr_15
      "1",                    # line_quantity (always '1')
      "Each",                 # unit_of_measure (always 'Each')
      padded_number(td.tcm_charge, 3)   # Line UOM selling price
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
