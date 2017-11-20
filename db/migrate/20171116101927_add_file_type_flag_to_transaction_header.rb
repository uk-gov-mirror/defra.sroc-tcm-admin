class AddFileTypeFlagToTransactionHeader < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_headers, :file_type_flag, :string
  end
end
