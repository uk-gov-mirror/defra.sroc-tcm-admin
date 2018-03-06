class AddTcmFinancialYearToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :tcm_financial_year, :string, index: true
  end
end
