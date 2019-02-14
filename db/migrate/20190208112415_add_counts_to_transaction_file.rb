class AddCountsToTransactionFile < ActiveRecord::Migration[5.1]
  def up
    change_table :transaction_files do |t|
      t.integer :credit_count
      t.integer :debit_count
      t.bigint :net_total
      t.string :file_reference
      t.index :file_reference
    end
  end

  def down
    change_table :transaction_files do |t|
      t.remove :credit_count, :debit_count, :net_total, :file_reference
    end
  end
end
