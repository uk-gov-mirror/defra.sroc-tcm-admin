# frozen_string_literal: true

class CreateTransactionFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :transaction_files do |t|
      t.references :regime, index: true
      t.string :region, null: false, index: true
      t.string :file_id
      t.string :state, null: false, default: 'initialised', index: true
      t.datetime :generated_at
      t.bigint :invoice_total
      t.bigint :credit_total
      t.timestamps
    end

    add_reference :transaction_details, :transaction_file, index: true
  end
end
