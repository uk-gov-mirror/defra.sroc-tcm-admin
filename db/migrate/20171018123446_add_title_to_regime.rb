# frozen_string_literal: true

class AddTitleToRegime < ActiveRecord::Migration[5.1]
  def change
    add_column :regimes, :title, :string

    [['pas', 'Installations'],['cfd', 'Water Quality'],['wabs', 'Waste']].each do |r|
      Regime.where(slug: r[0]).update_all(title: r[1])
    end
  end
end
