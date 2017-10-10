class AddTemporaryCessationToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :temporary_cessation, :boolean, null: false, default: false
    add_column :transaction_details, :temporary_cessation_start, :datetime
    add_column :transaction_details, :temporary_cessation_end, :datetime
  end
end
