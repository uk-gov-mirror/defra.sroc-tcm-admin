require 'test_helper.rb'

class TransactionExportServiceTest < ActiveSupport::TestCase
  include RegimePresenter, GenerateHistory

  def setup
    @regime = regimes(:cfd)
    @exporter = TransactionExportService.new(@regime)
    @permit_store = PermitStorageService.new(@regime)
  end

  def test_export_generates_csv_data
    transactions = @regime.transaction_details.unbilled
    assert transactions.count > 0, "No TTBB data"
    data = @exporter.export(presenter.wrap(transactions))
    idx = 0
    CSV.parse(data, headers: true) do |row|
      assert_equal @exporter.regime_columns, row.headers()
      assert_equal row["Reference 1"], transactions[idx].reference_1
      idx += 1
    end
  end

  def test_export_looks_up_permit_category_description
    transactions = @regime.transaction_details.unbilled
    code = permit_categories(:cfd).code

    assert transactions.count > 0, "No TTBB data"
    transactions.update_all(category: code, category_description: nil)

    data = @exporter.export(presenter.wrap(transactions))
    idx = 0

    CSV.parse(data, headers: true) do |row|
      assert_equal @exporter.regime_columns, row.headers()
      category = @permit_store.code_for_financial_year(code, row["Tcm Financial Year"])
      if category
        assert_equal category.description, row["Category Description"]
      else
        assert_nil row["Category Description"]
      end
      idx += 1
    end
  end

  def test_export_history_generates_csv_data
    generate_historic_cfd
    transactions = @regime.transaction_details.historic
    assert transactions.count > 0, "No historic test data"
    data = @exporter.export_history(presenter.wrap(transactions))
    idx = 0
    CSV.parse(data, headers: true) do |row|
      assert_equal @exporter.regime_history_columns, row.headers()
      assert_equal row["Reference 1"], transactions[idx].reference_1
      idx += 1
    end
  end

  def test_regime_columns_returns_correct_columns
    expected = [
      "Customer Reference",
      "Transaction Date",
      "Transaction Type",
      "Transaction Reference",
      "Related Reference",
      "Currency Code",
      "Header Narrative",
      "Header Attr 1",
      "Header Attr 2",
      "Header Attr 3",
      "Header Attr 4",
      "Header Attr 5",
      "Header Attr 6",
      "Header Attr 7",
      "Header Attr 8",
      "Header Attr 9",
      "Header Attr 10",
      "Currency Line Amount",
      "Line Vat Code",
      "Line Area Code",
      "Line Description",
      "Line Income Stream Code",
      "Line Context Code",
      "Line Attr 1",
      "Line Attr 2",
      "Line Attr 3",
      "Line Attr 4",
      "Line Attr 5",
      "Line Attr 6",
      "Line Attr 7",
      "Line Attr 8",
      "Line Attr 9",
      "Line Attr 10",
      "Line Attr 11",
      "Line Attr 12",
      "Line Attr 13",
      "Line Attr 14",
      "Line Attr 15",
      "Line Quantity",
      "Unit Of Measure",
      "Currency Unit Of Measure Price",
      "Reference 1",
      "Reference 2",
      "Reference 3",
      "Variation",
      "Temporary Cessation Flag",
      "Category",
      "Category Description",
      "Period Start",
      "Period End",
      "Tcm Financial Year",
      "Original Filename",
      "Original File Date",
      "Pro Rata Days",
      "Currency Baseline Charge",
      "Currency Tcm Charge"]
    assert_equal expected, @exporter.regime_columns
  end

  def test_regime_history_columns_returns_correct_columns
    expected = [
      "Customer Reference",
      "Transaction Date",
      "Transaction Type",
      "Transaction Reference",
      "Related Reference",
      "Currency Code",
      "Header Narrative",
      "Header Attr 1",
      "Header Attr 2",
      "Header Attr 3",
      "Header Attr 4",
      "Header Attr 5",
      "Header Attr 6",
      "Header Attr 7",
      "Header Attr 8",
      "Header Attr 9",
      "Header Attr 10",
      "Currency Line Amount",
      "Line Vat Code",
      "Line Area Code",
      "Line Description",
      "Line Income Stream Code",
      "Line Context Code",
      "Line Attr 1",
      "Line Attr 2",
      "Line Attr 3",
      "Line Attr 4",
      "Line Attr 5",
      "Line Attr 6",
      "Line Attr 7",
      "Line Attr 8",
      "Line Attr 9",
      "Line Attr 10",
      "Line Attr 11",
      "Line Attr 12",
      "Line Attr 13",
      "Line Attr 14",
      "Line Attr 15",
      "Line Quantity",
      "Unit Of Measure",
      "Currency Unit Of Measure Price",
      "Reference 1",
      "Reference 2",
      "Reference 3",
      "Variation",
      "Temporary Cessation Flag",
      "Category",
      "Category Description",
      "Period Start",
      "Period End",
      "Tcm Financial Year",
      "Original Filename",
      "Original File Date",
      "Pro Rata Days",
      "Currency Baseline Charge",
      "Currency Tcm Charge",
      "Generated Filename",
      "Tcm File Date",
      "Tcm Transaction Type",
      "Tcm Transaction Reference"]
    assert_equal expected, @exporter.regime_history_columns
  end
end

