class AddUniqueConstraintToRegimes < ActiveRecord::Migration[5.1]
  def change
    remove_index :regimes, :name
    add_index :regimes, :name, unique: true
  end
end
