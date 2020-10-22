# frozen_string_literal: true

class AddCategoryToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :category, :string
  end
end
