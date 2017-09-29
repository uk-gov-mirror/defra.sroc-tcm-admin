class AddStatusToTransactionDetail < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :status, :string, null: false, default: "unbilled", index: true
  end
end
