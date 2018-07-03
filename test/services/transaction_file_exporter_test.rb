require 'test_helper.rb'

class TransactionFileExporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @regime = regimes(:cfd)
    @region = 'A'
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @transaction_1 = transaction_details(:cfd)
    @transaction_2 = @transaction_1.dup

    @transaction_2.customer_reference ='A1234000A'
    @transaction_2.transaction_type = 'C'
    @transaction_2.line_description = 'Consent No - ABCD/9999/1/2'
    @transaction_2.reference_1 = 'ABCD/9999/1/2'
    @transaction_2.line_amount = -1234
    @transaction_2.unit_of_measure_price = -1234

    [@transaction_1, @transaction_2].each do |t|
      t.category = '2.3.4'
      t.status = 'unbilled'
      t.tcm_charge = t.line_amount
      t.tcm_financial_year = '1819'
      set_charge_calculation(t)
    end

    @exporter = TransactionFileExporter.new(@regime, @region, @user)
  end

  def test_export_creates_file_record
    assert_difference 'TransactionFile.count' do
      @exporter.export
    end
  end

  def test_export_queues_job_for_generating_file
    assert_enqueued_with(job: FileExportJob) do
      @exporter.export
    end
  end

  def test_export_sets_user_on_file_record
    @exporter.export
    assert_equal(@user, TransactionFile.last.user)
  end

  def test_export_creates_file_with_all_billable_transactions
    @exporter.export

    file = TransactionFile.last
    assert_equal 2, file.transaction_details.count
    assert_includes file.transaction_details, @transaction_1
    assert_includes file.transaction_details, @transaction_2
  end

  def test_export_sets_permit_category_description_on_transaction
    @exporter.export
    file = TransactionFile.last
    @exporter.generate_output_file(file)

    store = PermitStorageService.new(@regime)

    file.transaction_details.each do |td|
      pc = store.code_for_financial_year(td.category,
                                         td.tcm_financial_year)
      assert_equal(pc.description, td.category_description)
    end
  end

  def test_export_creates_audit_record
    assert_difference 'AuditLog.count' do
      @exporter.export
    end

    file = TransactionFile.last
    log = AuditLog.last
    assert_equal('create', log.action)
    assert_equal(file.audit_logs.last.id, log.id)
  end

  def set_charge_calculation(transaction)
    transaction.charge_calculation = {
      'calculation' => {
        'chargeAmount' => transaction.tcm_charge.abs,
        'decisionPoints' => {
          'baselineCharge' => 196803,
          'percentageAdjustment' => 0
        }
      },
      'generatedAt' => '10-AUG-2017'
    }
    transaction.save!
  end
end
