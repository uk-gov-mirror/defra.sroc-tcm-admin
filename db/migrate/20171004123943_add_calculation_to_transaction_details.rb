class AddCalculationToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :calculated_charge, :integer, limit: 8
    add_column :transaction_details, :charge_calculated_at, :datetime
  end
end
