# frozen_string_literal: true

class AddExtraTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :filename, :string
    add_column :transaction_details, :reference_1, :string, index: true
    add_column :transaction_details, :reference_2, :string, index: true
    add_column :transaction_details, :reference_3, :string, index: true
  end
end
