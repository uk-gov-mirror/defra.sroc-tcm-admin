class AddCategoryConfidenceLevelToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :category_confidence_level, :integer, index: true
  end
end
