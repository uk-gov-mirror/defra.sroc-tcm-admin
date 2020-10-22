# frozen_string_literal: true

class AddFileDetailsToTransactions < ActiveRecord::Migration[5.1]
  def change
    add_column :transaction_headers, :filename, :string, index: true
    add_column :transaction_details, :original_filename, :string, index: true
    add_column :transaction_details, :original_file_date, :datetime, index: true
  end
end
