# frozen_string_literal: true

class CreateExclusionReasons < ActiveRecord::Migration[5.1]
  def change
    create_table :exclusion_reasons do |t|
      t.references :regime, index: true
      t.string :reason, null: false
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :exclusion_reasons, [:regime_id, :reason], unique: true
  end
end
