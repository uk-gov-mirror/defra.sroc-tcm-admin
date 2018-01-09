class CreateSequenceCounters < ActiveRecord::Migration[5.1]
  def change
    create_table :sequence_counters do |t|
      t.references :regime
      t.string :region, null: false
      t.integer :file_number, null: false, default: 1
      t.integer :invoice_number, null: false, default: 1

      t.timestamps
    end

    add_index :sequence_counters, [:regime_id, :region], unique: true
  end
end
