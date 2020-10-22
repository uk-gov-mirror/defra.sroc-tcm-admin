# frozen_string_literal: true

class PasTransactionFilePresenter < TransactionFilePresenter
  def detail_row(table_data, idx)
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
      table_data.site_address,                 # line_description
      "PT",                                    # line income stream code
      table_data.line_context_code,
      table_data.permit_reference,             # line_attr_1
      table_data.period,                       # line_attr_2
      table_data.category,                     # line_attr_3
      table_data.pro_rata_days,                # line_attr_4
      table_data.category_description,         # was line_attr_5
      table_data.baseline_charge,              # line_attr_6
      table_data.compliance_band,              # line_attr_7 (compliance band)
      table_data.compliance_band_adjustment,   # line_attr_8
      "",                                      # line_attr_9   future - performance band
      "",                                      # line_attr_10  future - performance adjustment
      "",                                      # line_attr_11  future - pre-construction flag
      table_data.temporary_cessation_file,     # line_attr_12
      "",                                      # line_attr_13
      "",                                      # line_attr_14
      "",                                      # line_attr_15
      "1",                                     # line_quantity (always '1')
      "Each",                                  # unit_of_measure (always 'Each')
      padded_number(table_data.tcm_charge, 3)  # Line UOM selling price
    ]
  end
end
