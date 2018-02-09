require 'test_helper.rb'

class AnnualBillingDataFileServiceTest < ActiveSupport::TestCase
  def setup
    @regime = regimes(:cfd)
    @service = AnnualBillingDataFileService.new(@regime)
    @service.stubs(:invoke_charge_calculation).returns(dummy_charge)
  end

  def test_new_upload_returns_instance_of_AnnualBillingDataFile
    upload = @service.new_upload
    assert_instance_of AnnualBillingDataFile, upload
  end

  def test_new_upload_returns_initialised_model
    upload = @service.new_upload
    assert_equal @regime, upload.regime
  end

  def test_find_locates_annual_billing_files_by_id
    data_file = annual_billing_data_files(:cfd)
    assert_equal data_file, @service.find(data_file.id)
  end

  def test_find_raises_not_found_error_when_unmatched
    bad_id = AnnualBillingDataFile.maximum(:id) + 10
    assert_raises(ActiveRecord::RecordNotFound) { @service.find(bad_id) }
  end

  def test_valid_file_returns_true_when_valid
    File.open(file_fixture('cfd_abd.csv'), "r") do |f|
      assert @service.valid_file?(f)
    end
  end

  def test_valid_file_returns_false_when_invalid
    File.open(file_fixture('invalid.csv'), "r") do |f|
      refute @service.valid_file?(f)
    end
  end

  def test_import_updates_matching_transactions_in_regime
    file = file_fixture('cfd_abd.csv')
    transaction = transaction_details(:cfd)
    assert_nil transaction.category
    refute transaction.temporary_cessation

    upload = prepare_upload(file)
    @service.import(upload, file)

    transaction.reload
    assert_equal "2.3.4", transaction.category
    assert transaction.temporary_cessation
  end

  def test_import_calculates_charge_for_updated_transactions
    file = file_fixture('cfd_abd.csv')
    transaction = transaction_details(:cfd)
    assert_nil transaction.charge_calculation

    upload = prepare_upload(file)
    @service.import(upload, file)

    transaction.reload
    assert_not_nil transaction.charge_calculation
  end

  def test_import_extracts_and_converts_calculated_charge_amount
    file = file_fixture('cfd_abd.csv')
    transaction = transaction_details(:cfd)
    assert_nil transaction.charge_calculation

    upload = prepare_upload(file)
    @service.import(upload, file)

    transaction.reload
    amt = (transaction.charge_calculation['calculation']['chargeValue'] * 100).round
    amt = -amt if transaction.line_amount.negative?
    assert_equal amt, transaction.tcm_charge
  end

  def test_import_does_not_update_transactions_outside_regime
    file = file_fixture('cfd_abd.csv')

    transaction = transaction_details(:pas)
    assert_nil transaction.category
    refute transaction.temporary_cessation

    upload = prepare_upload(file)
    @service.import(upload, file)

    transaction.reload
    assert_nil transaction.category
    refute transaction.temporary_cessation
  end

  def test_import_correctly_set_temporary_cessation
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)

    @service.import(upload, file)
    transaction = transaction_details(:cfd)
    assert_equal(true, transaction.temporary_cessation)

    transaction = transaction_details(:cfd_b)
    assert_equal(false, transaction.temporary_cessation)
  end

  def test_import_records_total_and_errors
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)
    transaction = transaction_details(:cfd)

    @service.import(upload, file)
    assert_equal 2, upload.success_count
    assert_equal 2, upload.failed_count
    assert_equal 2, upload.data_upload_errors.count
  end

  def prepare_upload(file)
    upload = @service.new_upload(filename: File.basename(file))
    upload.state.upload!
    upload
  end

  def dummy_charge
    {
      "uuid" => "8ae80f67-3879-4dd0-b03b-8531f986740d0",
      "generatedAt" => 2.seconds.ago.iso8601,
      "calculation" => {
        "chargeValue" => 1994.62,
        "environmentFlag" => "TEST",
        "decisionPoints" => {
          "baselineCharge" => 8865,
          "percentageAdjustment" => 3989.25,
          "temporaryCessation" => 1994.625,
          "complianceAdjustment" => 1994.625,
          "chargeType" => nil
        },
        "messages" => nil
      }
    }
  end
end
