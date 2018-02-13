class AddRetrospectiveFlagToSystemConfig < ActiveRecord::Migration[5.1]
  def change
    add_column :system_configs, :process_retrospectives, :boolean, null: false, default: true
  end
end
