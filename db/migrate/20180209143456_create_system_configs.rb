# frozen_string_literal: true

class CreateSystemConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :system_configs do |t|
      t.boolean :importing, null: false, default: false
      t.datetime :import_started_at

      t.timestamps
    end
  end
end
