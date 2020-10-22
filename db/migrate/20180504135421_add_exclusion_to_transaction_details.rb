# frozen_string_literal: true

class AddExclusionToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :excluded, :boolean, null: false,
      default: false, index: true
    add_column :transaction_details, :excluded_reason, :string
  end
end
