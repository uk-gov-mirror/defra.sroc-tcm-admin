# frozen_string_literal: true

class AddSlugToRegime < ActiveRecord::Migration[5.1]
  def self.up
    add_column :regimes, :slug, :string

    Regime.all.each do |regime|
      regime.send(:generate_slug)
      regime.save!
    end

    change_column :regimes, :slug, :string, null: false, index: true
  end

  def self.down
    remove_column :regimes, :slug
  end
end
