# frozen_string_literal: true

class AddFinancialYearConstraintsToPermitCategories < ActiveRecord::Migration[5.1]
  def change
    remove_index :permit_categories, [:code, :regime_id]
    remove_column :permit_categories, :display_order, :integer, null: false, default: 1000
    add_column :permit_categories, :valid_from, :string, null: false, default: "1819"
    add_column :permit_categories, :valid_to, :string
    add_index :permit_categories, [:code, :regime_id, :valid_from], unique: true

    add_column :transaction_details, :category_description, :string
  end
end
