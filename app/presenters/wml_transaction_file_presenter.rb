# frozen_string_literal: true

class WmlTransactionFilePresenter < TransactionFilePresenter
  def detail_row(table_data, idx)
    if table_data.credit?
      credit_detail_row(table_data, idx)
    else
      invoice_detail_row(table_data, idx)
    end
  end

  def credit_detail_row(table_data, idx)
    [
      "D",
      padded_number(idx),
      table_data.customer_reference,
      file_generated_at,
      table_data.tcm_transaction_type,
      table_data.tcm_transaction_reference,
      "",
      "GBP",
      "",                                      # header_narrative always blank
      file_generated_at,                       # header_attr_1
      "",                                      # header_attr_2
      "",                                      # header_attr_3
      "",                                      # header_attr_4
      "",                                      # header_attr_5
      "",                                      # header_attr_6
      "",                                      # header_attr_7
      "",                                      # header_attr_8
      "",                                      # header_attr_9
      "",                                      # header_attr_10
      padded_number(table_data.tcm_charge, 3), # line_amount
      "",                                      # line VAT code always blank
      table_data.line_area_code,
      table_data.credit_line_description,      # line_description
      "JT",                                    # line income stream code
      "",                                      # line_context_code
      "",                                      # line_attr_1
      table_data.line_attr_2,                  # line_attr_2
      table_data.line_attr_3,                  # line_attr_3
      "",                                      # line_attr_4
      "",                                      # was line_attr_5
      "",                                      # line_attr_6
      "",                                      # line_attr_7 (compliance band)
      "",                                      # temporary cessation
      "",                                      # line_attr_9   future - compliance band
      "",                                      # line_attr_10  future - compliance adjustment
      "",                                      # line_attr_11  future - performance band
      "",                                      # line_attr_12  future - performance adjustment
      "",                                      # line_attr_13
      "",                                      # line_attr_14
      "",                                      # line_attr_15
      "1",                                     # line_quantity (always '1')
      "Each",                                  # unit_of_measure (always 'Each')
      padded_number(table_data.tcm_charge, 3)  # Line UOM selling price
    ]
  end

  def invoice_detail_row(table_data, idx)
    [
      "D",
      padded_number(idx),
      table_data.customer_reference,
      file_generated_at,
      table_data.tcm_transaction_type,
      table_data.tcm_transaction_reference,
      "",
      "GBP",
      "",                     # header_narrative always blank
      file_generated_at,      # header_attr_1
      "",                     # header_attr_2
      "",                     # header_attr_3
      "",                     # header_attr_4
      "",                     # header_attr_5
      "",                     # header_attr_6
      "",                     # header_attr_7
      "",                     # header_attr_8
      "",                     # header_attr_9
      "",                     # header_attr_10
      padded_number(table_data.tcm_charge, 3), # line_amount
      "", # line VAT code always blank
      table_data.line_area_code,
      table_data.invoice_line_description, # line_description
      "JT",                   # line income stream code
      "",                     # line_context_code
      table_data.line_attr_3,         # line_attr_1
      table_data.period,              # line_attr_2
      table_data.category,            # line_attr_3
      table_data.pro_rata_days,       # line_attr_4
      table_data.category_description, # line_attr_5
      table_data.baseline_charge,     # line_attr_6
      table_data.line_attr_5,         # line_attr_7 (compliance band)
      table_data.compliance_band_with_percent, # line_attr_8
      "",                     # line_attr_9   future - performance band
      "",                     # line_attr_10  future - performance adjustment
      "",                     # line_attr_11  future - pre-construction flag
      table_data.temporary_cessation_adjustment, # line_attr_12
      "",                     # line_attr_13
      "",                     # line_attr_14
      "",                     # line_attr_15
      "1",                    # line_quantity (always '1')
      "Each",                 # unit_of_measure (always 'Each')
      padded_number(table_data.tcm_charge, 3)   # Line UOM selling price
    ]
  end

  protected

  def record_count
    transaction_details.count + 2
  end
end
