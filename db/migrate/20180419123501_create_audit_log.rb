# frozen_string_literal: true

class CreateAuditLog < ActiveRecord::Migration[5.1]
  def change
    create_table :audit_logs do |t|
      t.references :user, index: true
      t.string :auditable_type
      t.integer :auditable_id
      t.string :action, null: false, index: true
      t.json :payload
      t.timestamps
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
  end
end
