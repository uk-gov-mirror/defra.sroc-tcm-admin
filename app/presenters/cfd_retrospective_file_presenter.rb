class CfdRetrospectiveFilePresenter < CfdTransactionFilePresenter
  def detail_row(td, idx)
    [
      "D",
      padded_number(idx),
      td.customer_reference,
      td.transaction_date,
      td.tcm_transaction_type,
      td.tcm_transaction_reference,
      td.related_reference,
      td.currency_code,
      td.header_narrative,
      td.transaction_date,
      td.header_attr_2,
      td.header_attr_3,
      td.header_attr_4,
      td.header_attr_5,
      td.header_attr_6,
      td.header_attr_7,
      td.header_attr_8,
      td.header_attr_9,
      td.header_attr_10,
      padded_number(td.line_amount, 3),
      td.line_vat_code,
      td.line_area_code,
      td.line_description,
      td.line_income_stream_code,
      td.line_context_code,
      td.line_attr_1,
      td.line_attr_2,
      td.line_attr_3,
      td.line_attr_4,
      td.line_attr_5,
      td.line_attr_6,
      td.line_attr_7,
      td.line_attr_8,
      td.line_attr_9,
      td.line_attr_10,
      td.line_attr_11,
      td.line_attr_12,
      td.line_attr_13,
      td.line_attr_14,
      td.line_attr_15,
      td.line_quantity,
      td.unit_of_measure,
      td.padded_number(td.line_amount, 3)
    ]
  end
protected
  def trailer_invoice_total
    transaction_details.where(transaction_type: 'I').sum(:line_amount).to_i
  end

  def trailer_credit_total
    transaction_details.where(transaction_type: 'C').sum(:line_amount).to_i
  end
end
