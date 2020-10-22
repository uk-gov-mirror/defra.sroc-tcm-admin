# frozen_string_literal: true

class AddRetrospectiveCutOffDateToRegime < ActiveRecord::Migration[5.1]
  def change
    add_column :regimes, :retrospective_cut_off_date, :datetime, null: false, default: '1-APR-2018 00:00:00'

    remove_column :system_configs, :retrospective_cut_off_date, :datetime, null: false, default: '1-APR-2018 00:00:00'
  end
end
