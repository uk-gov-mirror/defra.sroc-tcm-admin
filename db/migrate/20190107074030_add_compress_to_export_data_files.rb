class AddCompressToExportDataFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :export_data_files, :compress, :boolean, null: false, default: true
    add_column :export_data_files, :exported_filename, :string
  end
end
