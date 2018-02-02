class AddAccessAndRolesToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :role, :integer, null: false, default: 0

    create_table :regime_users do |t|
      t.references :regime
      t.references :user
      t.boolean :enabled, null:false, default: false
      t.boolean :selected, null: false, default: false
      t.string :working_region
    end
    
    add_index :regime_users, [:regime_id, :user_id], unique: true
  end
end
