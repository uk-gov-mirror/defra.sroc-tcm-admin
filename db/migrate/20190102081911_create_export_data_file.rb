# frozen_string_literal: true

class CreateExportDataFile < ActiveRecord::Migration[5.1]
  def change
    create_table :export_data_files do |t|
      t.references :regime, index: true
      t.string :filename, null: false
      t.datetime :last_exported_at
      t.integer :status, null: false

      t.timestamps
    end
  end
end
