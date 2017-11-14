class AddPeriodDatesToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :period_start, :datetime, index: true
    add_column :transaction_details, :period_end, :datetime
  end
end
