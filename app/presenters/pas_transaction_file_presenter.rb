class PasTransactionFilePresenter < TransactionFilePresenter
  def detail_row(td, idx)
    [
      "D",
      padded_number(idx),
      td.customer_reference,
      file_generated_at,
      td.tcm_transaction_type,
      td.tcm_transaction_reference,
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
      padded_number(td.tcm_charge, 3),  # line_amount
      "",                     # line VAT code always blank
      td.line_area_code,
      td.site_address,        # line_description
      "PT",                   # line income stream code
      td.line_context_code,
      td.permit_reference,   # line_attr_1
      td.period,             # line_attr_2
      td.category,            # line_attr_3
      td.pro_rata_days,       # line_attr_4
      td.category_description, # was line_attr_5
      td.baseline_charge,     # line_attr_6
      td.compliance_band,     # line_attr_7 (compliance band)
      td.compliance_band_adjustment, # line_attr_8
      "",                     # line_attr_9   future - performance band
      "",                     # line_attr_10  future - performance adjustment
      "",                     # line_attr_11  future - pre-construction flag
      td.temporary_cessation_file,  # line_attr_12
      "",                     # line_attr_13
      "",                     # line_attr_14
      "",                     # line_attr_15
      "1",                    # line_quantity (always '1')
      "Each",                 # unit_of_measure (always 'Each')
      padded_number(td.tcm_charge, 3)   # Line UOM selling price
    ]
  end
end
