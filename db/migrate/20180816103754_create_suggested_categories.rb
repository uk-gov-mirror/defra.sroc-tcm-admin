class CreateSuggestedCategories < ActiveRecord::Migration[5.1]
  def change
    create_table :suggested_categories do |t|
      t.belongs_to :transaction_detail, index: true
      t.string :category
      t.integer :confidence_level, mull: false, index: true
      t.boolean :admin_lock, null: false, default: false
      t.string :suggestion_stage, null: false
      t.string :logic, null: false
      t.references :matched_transaction, foreign_key: { to_table: :transaction_details}
      t.timestamps
    end

    remove_column :transaction_details, :category_logic, :string
  end
end
