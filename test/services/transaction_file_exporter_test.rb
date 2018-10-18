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
    @transaction_3 = @transaction_1.dup

    @transaction_1.tcm_financial_year = '1819'

    @transaction_2.customer_reference ='A1234000A'
    @transaction_2.transaction_type = 'C'
    @transaction_2.line_description = 'Consent No - ABCD/9999/1/2'
    @transaction_2.reference_1 = 'ABCD/9999/1/2'
    @transaction_2.line_amount = -1234
    @transaction_2.unit_of_measure_price = -1234
    @transaction_2.tcm_financial_year = '1819'

    @transaction_3.customer_reference ='A9876000Z'
    @transaction_3.line_description = 'Consent No - WXYZ/99/2/1'
    @transaction_3.reference_1 = 'WXYZ/99/2/1'
    @transaction_3.tcm_financial_year = '1920'

    [@transaction_1, @transaction_2, @transaction_3].each do |t|
      t.category = '2.3.4'
      t.status = 'unbilled'
      t.tcm_charge = t.line_amount
      t.approved_for_billing = true
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

  def test_export_creates_file_with_all_approved_transactions
    @transaction_2.update_attributes(approved_for_billing: false)
    @exporter.export

    file = TransactionFile.last
    assert_equal 2, file.transaction_details.count
    assert_includes file.transaction_details, @transaction_1
    assert_not_includes file.transaction_details, @transaction_2
    assert_includes file.transaction_details, @transaction_3
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

  def test_export_includes_transactions_for_all_financial_years
    @exporter.export

    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    assert_includes file.transaction_details, @transaction_1
    assert_includes file.transaction_details, @transaction_2
    assert_includes file.transaction_details, @transaction_3
  end

  def test_cfd_splits_transaction_references_by_financial_year
    @exporter.export

    file = TransactionFile.last
    file.transaction_details.update_all(customer_reference: 'ABCD1234')
    @exporter.assign_cfd_transaction_references(file)
    assert_not_nil @transaction_1.reload.tcm_transaction_reference
    assert_not_nil @transaction_2.reload.tcm_transaction_reference
    assert_not_nil @transaction_3.reload.tcm_transaction_reference

    assert_equal @transaction_1.tcm_transaction_reference,
      @transaction_2.tcm_transaction_reference
    assert_not_equal @transaction_1.tcm_transaction_reference,
      @transaction_3.tcm_transaction_reference
  end

  def test_cfd_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999')
    @transaction_2.update_attributes(tcm_charge: @transaction_1.tcm_charge,
                                     customer_reference: 'AABBCCDD')
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_cfd_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_cfd_splits_transaction_references_by_line_context_code
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999',
                                        line_context_code: 'E')
    @transaction_1.update_attributes(line_context_code: 'A')

    # 1,2 and 3 same consent reference
    # 1 different context code
    # 3 different financial year
    @exporter.assign_cfd_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_financial_year
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: 'ABCD1234')
    @exporter.assign_wml_transaction_references(file)
    # 3 different references because split 1 invoice, 2 credit, 3 different FY
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999')
    @transaction_2.update_attributes(tcm_charge: @transaction_1.tcm_charge,
                                     customer_reference: 'AABBCCDD')
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_wml_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_credit_and_invoice
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999')
    # 1,2 and 3 same permit reference
    # 1 and 2 different credit/invoice
    # 3 different financial year
    @exporter.assign_wml_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_pas_assigns_transaction_references_correctly
  end

  def test_pas_splits_transaction_references_by_financial_year
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: 'ABCD1234')
    @exporter.assign_pas_transaction_references(file)
    # 3 different references because split 1 invoice, 2 credit, 3 different FY
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_pas_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999')
    @transaction_2.update_attributes(tcm_charge: @transaction_1.tcm_charge,
                                     customer_reference: 'AABBCCDD')
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_pas_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
  end

  def test_pas_splits_transaction_references_by_credit_and_invoice
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    
    file.transaction_details.update_all(customer_reference: 'ABCD1234',
                                        reference_1: 'ZZZZ9999')
    # 1,2 and 3 same permit reference
    # 1 and 2 different credit/invoice
    # 3 different financial year
    @exporter.assign_pas_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.
      pluck(:tcm_transaction_reference).count
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
