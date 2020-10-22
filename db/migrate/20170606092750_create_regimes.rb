# frozen_string_literal: true

class CreateRegimes < ActiveRecord::Migration[5.1]
  def change
    create_table :regimes do |t|
      t.string :name, null: false, index: true
      t.timestamps
    end
  end
end
