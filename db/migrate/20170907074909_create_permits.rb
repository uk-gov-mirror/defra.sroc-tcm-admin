# frozen_string_literal: true

class CreatePermits < ActiveRecord::Migration[5.1]
  def change
    create_table :permits do |t|
      t.references :regime, index: true
      t.string :permit_reference, null: false, index: true
      t.string :original_reference
      t.string :obs_original_reference
      t.string :version
      t.string :discharge_reference
      t.string :operator
      t.string :permit_category, null: false
      t.datetime :effective_date, null: false
      t.string :status, null: false
      t.boolean :pre_construction, null: false
      t.datetime :pre_construction_end
      t.boolean :temporary_cessation, null: false
      t.datetime :temporary_cessation_start
      t.datetime :temporary_cessation_end
      t.string :compliance_score
      t.string :compliance_band

      t.timestamps
    end
  end
end
