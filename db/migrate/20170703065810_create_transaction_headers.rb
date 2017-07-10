class CreateTransactionHeaders < ActiveRecord::Migration[5.1]
  def change
    create_table :transaction_headers do |t|
      t.references :regime, index: true
      t.string :feeder_source_code
      t.string :region
      t.integer :file_sequence_number
      t.string :bill_run_id
      t.datetime :generated_at
      t.integer :transaction_count
      t.integer :invoice_total
      t.integer :credit_total
      t.timestamps
    end
  end
end
