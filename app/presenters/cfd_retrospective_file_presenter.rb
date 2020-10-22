# frozen_string_literal: true

class CfdRetrospectiveFilePresenter < CfdTransactionFilePresenter
  def detail_row(table_data, idx)
    [
      "D",
      padded_number(idx),
      table_data.customer_reference,
      file_generated_at,
      table_data.tcm_transaction_type,
      table_data.tcm_transaction_reference,
      table_data.related_reference,
      table_data.currency_code,
      table_data.header_narrative,
      file_generated_at,
      table_data.header_attr_2,
      table_data.header_attr_3,
      table_data.header_attr_4,
      table_data.header_attr_5,
      table_data.header_attr_6,
      table_data.header_attr_7,
      table_data.header_attr_8,
      table_data.header_attr_9,
      table_data.header_attr_10,
      padded_number(table_data.line_amount, 3),
      table_data.line_vat_code,
      table_data.line_area_code,
      table_data.line_description,
      table_data.line_income_stream_code,
      table_data.line_context_code,
      table_data.line_attr_1,
      table_data.line_attr_2,
      table_data.line_attr_3,
      table_data.line_attr_4,
      table_data.line_attr_5,
      table_data.line_attr_6,
      table_data.line_attr_7,
      table_data.line_attr_8,
      table_data.line_attr_9,
      table_data.line_attr_10,
      table_data.line_attr_11,
      table_data.line_attr_12,
      table_data.line_attr_13,
      table_data.line_attr_14,
      table_data.line_attr_15,
      table_data.line_quantity,
      table_data.unit_of_measure,
      table_data.padded_number(table_data.line_amount, 3)
    ]
  end

  protected

  def trailer_invoice_total
    transaction_details.where(tcm_transaction_type: "I").sum(:line_amount).to_i
  end

  def trailer_credit_total
    transaction_details.where(tcm_transaction_type: "C").sum(:line_amount).to_i
  end
end
