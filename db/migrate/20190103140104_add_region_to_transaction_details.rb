# frozen_string_literal: true

class AddRegionToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :region, :string, index: true
  end
end
