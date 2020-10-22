# frozen_string_literal: true

class AddApprovalToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_details, :approved_for_billing, :boolean, null: false, default: false
    add_reference :transaction_details, :approver, foreign_key: { to_table: :users }
    add_column :transaction_details, :approved_for_billing_at, :datetime
  end
end
