class AddUserToTransactionFiles < ActiveRecord::Migration[5.1]
  def change
    add_reference :transaction_files, :user, foreign_key: true
  end
end
