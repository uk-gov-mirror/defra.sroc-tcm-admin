# frozen_string_literal: true

class AddTcmAttrsToTransactionDetails < ActiveRecord::Migration[5.1]
  def change
    change_table :transaction_details do |t|
      t.bigint :tcm_charge
      t.string :tcm_transaction_type
      t.string :tcm_transaction_reference
    end
  end
end
