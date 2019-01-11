require 'test_helper.rb'
require 'fileutils'

class StoreDataExportFileTest < ActiveSupport::TestCase
  include RegimePresenter, GenerateHistory

  def setup
    @regime = regimes(:cfd)
    @tmp_path = Rails.root.join('tmp', 'test')
    FileUtils.mkdir_p @tmp_path
    @cache_path = Rails.root.join('tmp', 'cache', 'export_data')
  end

  def teardown
    edf = @regime.export_data_file
    filename = edf.exported_filename
    path = File.join(@tmp_path, File.basename(filename))
    File.delete(path) #if File.exists?(path)
    path = File.join(@cache_path, File.basename(filename))
    File.delete(path) #if File.exists?(filename)
  end

  def test_it_copies_local_file_to_csv_export_store
    # generate an export file
    transactions = @regime.transaction_details
    assert transactions.count > 0, "No transaction data"

    FileStorageService.any_instance.stubs(:zone_path).
      returns(@tmp_path.join('cfd_transactions.csv'))

    result = ExportTransactionData.call(regime: @regime)
    assert result.success?, "Did not create test file"

    filename = result.filename
    result = StoreDataExportFile.call(regime: @regime,
                                      filename: filename)
    assert result.success?, "Failed to store file"

    # when Rails.env.development? or Rails.env.test? the file
    # should be stored locally rather than S3
    assert File.exist?(File.join(@tmp_path, File.basename(filename))),
      "Didn't find stored file"
  end
end
