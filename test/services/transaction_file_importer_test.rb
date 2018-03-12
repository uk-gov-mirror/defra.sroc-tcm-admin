require 'test_helper.rb'

class TransactionFileImporterTest < ActiveSupport::TestCase
  def setup
    @importer = TransactionFileImporter.new
    @header = @importer.import(file_fixture('cfd_transaction.dat'), 'cfd123.dat')
  end

  def test_import_creates_transaction_header_record
    assert_difference('TransactionHeader.count', 1) do
      @importer.import(file_fixture('cfd_transaction.dat'), 'cfd123.dat')
    end
  end

  def test_header_has_correct_regime
    assert_equal('CFD', @header.regime.name)
  end

  def test_header_has_correct_region
    assert_equal('E', @header.region)
  end

  def test_header_has_correct_file_type_flag
    assert_equal('I', @header.file_type_flag)
  end

  def test_header_has_correct_file_sequence_number
    assert_equal(358, @header.file_sequence_number)
  end

  def test_header_has_correct_file_date
    assert_equal(Date.new(2015, 1, 20), @header.generated_at.to_date)
  end

  def test_import_creates_transaction_detail_records
    assert_difference('TransactionDetail.count', 2) do
      @importer.import(file_fixture('cfd_transaction.dat'), 'cfd123.dat')
    end
  end

  def test_imported_transactions_have_default_temporary_cessation_value
    @header.transaction_details.each do |transaction|
      assert_equal(false, transaction.temporary_cessation)
    end
  end
end
