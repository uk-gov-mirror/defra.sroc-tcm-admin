class AddCountsToTransactionFile < ActiveRecord::Migration[5.1]
  def up
    change_table :transaction_files do |t|
      t.integer :credit_count
      t.integer :debit_count
      t.bigint :net_total
      t.string :file_reference
      t.index :file_reference
    end

    TransactionFile.all.each do |f|
      f.credit_count = f.transaction_details.credits.count
      f.debit_count = f.transaction_details.invoices.count
      f.net_total = f.invoice_total + f.credit_total
      f.file_reference = f.base_filename
      f.save!
    end
  end

  def down
    change_table :transaction_files do |t|
      t.remove :credit_count, :debit_count, :net_total, :file_reference
    end
  end
end
