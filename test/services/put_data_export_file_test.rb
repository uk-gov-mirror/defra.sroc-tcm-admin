# frozen_string_literal: true

require "test_helper"
require "fileutils"

class PutDataExportFileTest < ActiveSupport::TestCase
  include FileStorage
  include GenerateHistory
  include RegimePresenter

  def setup
    @regime = regimes(:cfd)
    @store = archive_file_store
    @tmp_path = @store.base_path
    FileUtils.mkdir_p @tmp_path
    @cache_path = Rails.root.join("tmp", "cache", "export_data")
  end

  def teardown
    edf = @regime.export_data_file
    filename = edf.exported_filename
    path = File.join(@tmp_path, "csv", File.basename(filename))
    File.delete(path) # if File.exists?(path)
    path = File.join(@cache_path, File.basename(filename))
    File.delete(path) # if File.exists?(filename)
  end

  def test_it_copies_local_file_to_csv_export_store
    # generate an export file
    transactions = @regime.transaction_details
    assert transactions.count.positive?, "No transaction data"

    result = ExportTransactionData.call(regime: @regime)
    assert result.success?, "Did not create test file"

    filename = result.filename
    result = PutDataExportFile.call(filename: filename)
    assert result.success?, "Failed to store file"

    # when Rails.env.development? or Rails.env.test? the file
    # should be stored locally rather than S3
    assert File.exist?(File.join(@tmp_path, "csv", File.basename(filename))),
           "Didn't find stored file"
  end
end
