class CreateBillRuns < ActiveRecord::Migration[5.1]
  def change
    create_table :bill_runs do |t|
      t.uuid    :bill_run_id
      t.string  :region
      t.string  :regime
      t.boolean :pre_sroc
      t.timestamps
    end
  end
end
