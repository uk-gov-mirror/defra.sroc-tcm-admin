class AddFileGenerationToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :generated_filename, :string, index: true
    add_column :transaction_details, :generated_file_at, :datetime, index: true
  end
end
