# frozen_string_literal: true

class AddStatusAndExclusionReasonToTransactionHeader < ActiveRecord::Migration[5.1]
  def change
    change_table :transaction_headers do |t|
      t.boolean :removed, null: false, default: false
      t.string :removal_reference
      t.text :removal_reason
      t.references :removed_by, foreign_key: { to_table: :users }, index: true
      t.datetime :removed_at
      t.string :file_reference, index: true
    end

    reversible do |dir|
      dir.up do
        TransactionHeader.all.each do |h|
          h.send :generate_file_reference
          h.save!
        end
      end
    end
  end
end
