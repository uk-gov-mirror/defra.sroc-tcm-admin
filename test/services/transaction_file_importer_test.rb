# frozen_string_literal: true

require "test_helper"

class TransactionFileImporterTest < ActiveSupport::TestCase
  def setup
    @importer = TransactionFileImporter.new
    @header = @importer.import(file_fixture("cfd_transaction.dat"), "cfd123.dat")
  end

  def test_import_creates_transaction_header_record
    assert_difference("TransactionHeader.count", 1) do
      @importer.import(file_fixture("cfd_transaction.dat"), "cfd123.dat")
    end
  end

  def test_header_has_correct_regime
    assert_equal("CFD", @header.regime.name)
  end

  def test_header_has_correct_region
    assert_equal("E", @header.region)
  end

  def test_header_has_correct_file_type_flag
    assert_equal("I", @header.file_type_flag)
  end

  def test_header_has_correct_file_sequence_number
    assert_equal(358, @header.file_sequence_number)
  end

  def test_header_has_correct_file_date
    assert_equal(Date.new(2015, 1, 20), @header.generated_at.to_date)
  end

  def test_import_creates_transaction_detail_records
    assert_difference("TransactionDetail.count", 2) do
      @importer.import(file_fixture("cfd_transaction.dat"), "cfd123.dat")
    end
  end

  def test_import_creates_detail_records_with_correct_consent_info
    @header.transaction_details.each do |td|
      assert_equal("071919/1/3", td.reference_1)
      assert_equal("1", td.reference_2)
      assert_equal("3", td.reference_3)
    end
  end

  def test_populates_variation_field
    @header.transaction_details.each do |transaction|
      assert_not_nil(transaction.variation)
    end
  end

  def test_imported_transactions_have_default_temporary_cessation_value
    @header.transaction_details.each do |transaction|
      assert_equal(false, transaction.temporary_cessation)
    end
  end

  def test_extract_consent_fields_extracts_references
    # this is the line_description fields extracted from the complete annual billing
    # files for CFD 18/19
    File.foreach(file_fixture("cfd_line_descriptions.txt")).with_index do |line, idx|
      line.chomp!
      fields = @importer.extract_consent_fields(line)
      str = if line.start_with? "Consent"
              "Consent No - #{fields[:reference_1]}"
            else
              "Authorisation No - #{fields[:reference_1]}"
            end
      assert_equal(line, str, "Fail: #{idx}: #{line}")

      arr = line.split("/")
      assert_equal(arr.second_to_last, fields[:reference_2], "Invalid version extracted #{idx}: #{line}")
      assert_equal(arr.last, fields[:reference_3], "Invalid discharge extracted #{idx}: #{line}")
    end
  end

  def test_import_creates_transactions_with_whitespace_consents
    header = @importer.import(file_fixture("cfd_trans_consents.dat"), "cfd456.dat")

    assert_equal(2, header.transaction_details.count)

    header.transaction_details.each do |td|
      assert_equal("T/40/00817/O */1/2", td.reference_1)
      assert_equal("1", td.reference_2)
      assert_equal("2", td.reference_3)
    end
  end

  def test_extract_charge_code_extracts_code_when_present
    d = "Charge Code 1 at Wigwam Wood Landfill Site, Wigwam Road, Tepee," \
      "West Sussex, RH1 3AA, Permit Ref: AB1234AB/A001"
    assert_equal "1", @importer.extract_charge_code(d)

    d = "In cancellation of Charge Code 3 at Haystack Wood Pig Site, Eggham Road," \
      "Ham, Peas and Chips, West County, AA12 1AA, Permit Ref: AA3700BB/A001"
    assert_equal "3", @importer.extract_charge_code(d)
  end

  def test_extract_charge_code_returns_nil_when_no_code_found
    d = "There is no Charge Code here, so none shall be returned"
    assert_nil @importer.extract_charge_code(d)
  end

  def test_determine_financial_year_handles_2000_onwards_dates
    [%w[10-JUL-2010 1011],
     %w[1-FEB-2019 1819],
     %w[22-MAR-2000 9900],
     %w[1-APR-2001 0102]].each do |y|
       d = Date.parse(y[0])
       assert_equal y[1], @importer.determine_financial_year(d)
     end
  end

  def test_determine_financial_year_handles_pre_2000_dates
    [%w[10-JUL-1995 9596],
     %w[1-FEB-1997 9697],
     %w[22-MAR-1998 9798],
     %w[1-APR-1999 9900]].each do |y|
       d = Date.parse(y[0])
       assert_equal y[1], @importer.determine_financial_year(d)
     end
  end
end
