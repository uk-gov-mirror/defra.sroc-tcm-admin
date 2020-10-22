# frozen_string_literal: true

class AddVariationToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :variation, :string
  end
end
