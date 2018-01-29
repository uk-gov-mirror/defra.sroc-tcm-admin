class CreateAnnualBillingDataFiles < ActiveRecord::Migration[5.1]
  def change
    create_table :annual_billing_data_files do |t|
      t.references :regime, index: true
      t.string :filename, null: false
      t.string :status, null: false, default: 'new'
      t.integer :number_of_records, null: false, default: 0
      t.integer :success_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.timestamps
    end

    create_table :data_upload_errors do |t|
      t.references :annual_billing_data_file, index: true
      t.integer :line_number, null: false
      t.string :message, null: false
    end
  end
end
