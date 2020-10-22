# frozen_string_literal: true

class CreateTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :transaction_details do |t|
      t.references :transaction_header, index: true
      t.integer :sequence_number, index: true
      t.string :customer_reference, index: true
      t.datetime :transaction_date
      t.string :transaction_type
      t.string :transaction_reference
      t.string :related_reference
      t.string :currency_code
      t.string :header_narrative
      t.string :header_attr_1
      t.string :header_attr_2
      t.string :header_attr_3
      t.string :header_attr_4
      t.string :header_attr_5
      t.string :header_attr_6
      t.string :header_attr_7
      t.string :header_attr_8
      t.string :header_attr_9
      t.string :header_attr_10
      t.integer :line_amount
      t.string :line_vat_code
      t.string :line_area_code
      t.string :line_description
      t.string :line_income_stream_code
      t.string :line_context_code
      t.string :line_attr_1
      t.string :line_attr_2
      t.string :line_attr_3
      t.string :line_attr_4
      t.string :line_attr_5
      t.string :line_attr_6
      t.string :line_attr_7
      t.string :line_attr_8
      t.string :line_attr_9
      t.string :line_attr_10
      t.string :line_attr_11
      t.string :line_attr_12
      t.string :line_attr_13
      t.string :line_attr_14
      t.string :line_attr_15
      t.integer :line_quantity
      t.string :unit_of_measure
      t.integer :unit_of_measure_price

      t.timestamps
    end
  end
end
