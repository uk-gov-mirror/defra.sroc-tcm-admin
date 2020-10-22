# frozen_string_literal: true

class AddCustomerNameToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :customer_name, :string
  end
end
