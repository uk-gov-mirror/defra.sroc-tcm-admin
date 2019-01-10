require 'test_helper.rb'

class ExportTransactionDataTest < ActiveSupport::TestCase
  include RegimePresenter, GenerateHistory

  def setup
    @regime = regimes(:cfd)
  end

  def teardown
    edf = @regime.export_data_file
    filename = Rails.root.join('tmp', edf.filename)
    File.delete(filename) if File.exists?(filename)
  end

  def test_it_generates_a_file
    transactions = @regime.transaction_details
    assert transactions.count > 0, "No transaction data"
    result = ExportTransactionData.call(regime: @regime)
    assert result.success?, "Result unsuccessful"

    assert File.exists?(result.filename), "File not found #{result.filename}"
    assert_equal @regime.export_data_file.reload.exported_filename,
      File.basename(result.filename), "Filenames do not match"
  end

  def test_it_exports_csv_data
    transactions = @regime.transaction_details.
      includes(:suggested_category,
               :transaction_header,
               :transaction_file).
               order(:region, :transaction_date, :id)

    assert transactions.count > 0, "No transaction data"
    result = ExportTransactionData.call(regime: @regime)
    assert result.success?, "Result unsuccessful"

    data = File.read(result.filename)

    idx = 0
    CSV.parse(data, headers: true) do |row|
      t = presenter.new(transactions[idx])
      ExportFileFormat::ExportColumns.each do |c|
        val = row[c[:heading]]
        val = "" if val.nil?

        assert_equal t.send(c[:accessor]).to_s, val,
          "CSV column error in '#{c[:accessor]}' [#{idx}]"
      end
      idx += 1
    end
    assert_equal transactions.count, idx, "Row count mismatch"
  end

  def test_it_exports_the_correct_columns
    expected = [
      'Customer Reference',
      'Transaction Date',
      'Transaction Type',
      'Transaction Reference',
      'Related Reference',
      'Currency Code',
      'Header Narrative',
      'Header Attr 1',
      'Header Attr 2',
      'Header Attr 3',
      'Header Attr 4',
      'Header Attr 5',
      'Header Attr 6',
      'Header Attr 7',
      'Header Attr 8',
      'Header Attr 9',
      'Header Attr 10',
      'Currency Line Amount',
      'Line VAT Code',
      'Line Area Code',
      'Line Description',
      'Line Income Stream Code',
      'Line Context Code',
      'Line Attr 1',
      'Line Attr 2',
      'Line Attr 3',
      'Line Attr 4',
      'Line Attr 5',
      'Line Attr 6',
      'Line Attr 7',
      'Line Attr 8',
      'Line Attr 9',
      'Line Attr 10',
      'Line Attr 11',
      'Line Attr 12',
      'Line Attr 13',
      'Line Attr 14',
      'Line Attr 15',
      'Line Quantity',
      'Unit Of Measure',
      'Currency Unit Of Measure Price',
      'Reference 1',
      'Reference 2',
      'Reference 3',
      'Customer Name',
      'Variation',
      'Temporary Cessation Flag',
      'Category',
      'Category Description',
      'Period Start',
      'Period End',
      'TCM Financial Year',
      'Original Filename',
      'Original File Date',
      'Pro Rata Days',
      'Currency Baseline Charge',
      'Currency TCM Charge',
      'Generated Filename',
      'Generated File Date',
      'TCM Transaction Type',
      'TCM Transaction Reference',
      'Region',
      'Transaction Status',
      'Pre-SRoC',
      'Excluded',
      'Exclusion Reason',
      'Suggested Category',
      'Confidence Level',
      'Suggestion Overridden',
      'Override Lock',
      'Assignment Outcome',
      'Suggestion Stage',
      'Checked Flag',
      'Checked Date',
      'TCM Compliance %'
    ]

    assert_equal expected,
      ExportFileFormat::ExportColumns.map { |c| c[:heading] },
      "Column mismatch"
  end
end
