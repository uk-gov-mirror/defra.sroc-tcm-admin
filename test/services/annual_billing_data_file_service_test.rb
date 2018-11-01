require 'test_helper.rb'

class AnnualBillingDataFileServiceTest < ActiveSupport::TestCase
  include ChargeCalculation

  def setup
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    @service = AnnualBillingDataFileService.new(@regime, @user)

    build_mock_calculator
    # @calculator = build_mock_calculator
    # @service.stubs(:calculator).returns(@calculator)
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
    transaction = sroc_transaction
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
    transaction = sroc_transaction
    assert_nil transaction.charge_calculation

    upload = prepare_upload(file)
    @service.import(upload, file)

    transaction.reload
    assert_not_nil transaction.charge_calculation
  end

  def test_import_extracts_and_converts_calculated_charge_amount
    file = file_fixture('cfd_abd.csv')
    transaction = sroc_transaction
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

    transaction = sroc_transaction
    transaction_2 = transaction.dup
    transaction_2.reference_1 = "ANNF/1754/1/1"
    transaction_2.save

    @service.import(upload, file)
    assert_equal(true, transaction.reload.temporary_cessation)
    assert_equal(false, transaction_2.reload.temporary_cessation)
  end

  def test_import_handles_zero_variation
    file = file_fixture('cfd_abd_zero_variation.csv')
    upload = prepare_upload(file)

    transaction = sroc_transaction
    transaction_2 = transaction.dup
    transaction_2.reference_1 = "ANNF/1754/1/1"
    transaction_2.save
    transaction_3 = transaction.dup
    transaction_3.reference_1 = "ZNNNF/1754/1/1"
    transaction_3.save

    @service.import(upload, file)
    assert_equal("22%", transaction.reload.variation)
    assert_equal("0%", transaction_2.reload.variation)
    assert_equal("84%", transaction_3.reload.variation)
  end

  def test_import_stores_variation_with_an_percent_suffix
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)

    transaction = sroc_transaction
    transaction_2 = transaction.dup
    transaction_2.reference_1 = "ANNF/1754/1/1"
    transaction_2.save

    @service.import(upload, file)
    assert transaction.reload.variation.end_with?('%')
    assert transaction_2.reload.variation.end_with?('%')
  end

  def test_import_records_total_and_errors
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)
    transaction = sroc_transaction
    transaction_2 = transaction.dup
    transaction_2.reference_1 = "ANNF/1754/1/1"
    transaction_2.save

    @service.import(upload, file)
    assert_equal 2, upload.success_count
    assert_equal 2, upload.failed_count
    assert_equal 2, upload.data_upload_errors.count
  end

  def test_import_creates_audit_records
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)
    transaction = sroc_transaction
    transaction_2 = transaction.dup
    transaction_2.reference_1 = "ANNF/1754/1/1"
    transaction_2.save!

    assert_difference('AuditLog.count', 2) do
      @service.import(upload, file)
    end
    assert_equal(@user, AuditLog.last.user)
  end

  def test_import_creates_audit_log_of_changes
    file = file_fixture('cfd_abd.csv')
    upload = prepare_upload(file)

    transaction = sroc_transaction

    @service.import(upload, file)

    log = transaction.reload.audit_logs.last
    changes = log.payload['modifications']

    assert_equal([nil, '2.3.4'], changes['category'])
    assert_equal([false, true], changes['temporary_cessation'])
    assert_equal([nil, '88%'], changes['variation'])
    assert_not_nil(changes['charge_calculation'])
    assert_not_nil(changes['tcm_charge'])
  end

  def prepare_upload(file)
    upload = @service.new_upload(filename: File.basename(file))
    upload.state.upload!
    upload
  end

  def sroc_transaction
    transaction = transaction_details(:cfd)
    transaction.tcm_financial_year = '1819'
    transaction.period_start = '1-APR-2018'
    transaction.period_end = '31-MAR-2019'
    transaction.save!
    transaction
  end
end
