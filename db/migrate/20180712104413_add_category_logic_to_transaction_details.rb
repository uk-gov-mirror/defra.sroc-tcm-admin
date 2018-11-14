class AddCategoryLogicToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :category_logic, :string
  end
end
