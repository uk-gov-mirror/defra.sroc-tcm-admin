class AddGeneratedFileHashToExportDataFiles < ActiveRecord::Migration[5.1]
  def change
    add_column :export_data_files, :exported_filename_hash, :string
  end
end
