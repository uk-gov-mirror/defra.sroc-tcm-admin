# frozen_string_literal: true

class CreatePermitCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :permit_categories do |t|
      t.references :regime, index: true
      t.string :code, null: false
      t.string :description
      t.string :status, null: false
      t.integer :display_order, null: false, default: 1000

      t.timestamps
    end

    add_index :permit_categories, [:code, :regime_id], unique: true
  end
end
