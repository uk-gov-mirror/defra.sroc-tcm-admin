# frozen_string_literal: true

class AddCanGenerateExportToSystemConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :system_configs, :can_generate_export, :boolean, null: false, default: false
  end
end
