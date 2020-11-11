# frozen_string_literal: true

require "test_helper"

class TransactionFileExporterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @regime = regimes(:cfd)
    @region = "A"
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @transaction1 = transaction_details(:cfd)
    @transaction2 = @transaction1.dup
    @transaction3 = @transaction1.dup

    @transaction1.tcm_financial_year = "1819"

    @transaction2.customer_reference = "A1234000A"
    @transaction2.transaction_type = "C"
    @transaction2.line_description = "Consent No - ABCD/9999/1/2"
    @transaction2.reference_1 = "ABCD/9999/1/2"
    @transaction2.line_amount = -1234
    @transaction2.unit_of_measure_price = -1234
    @transaction2.tcm_financial_year = "1819"

    @transaction3.customer_reference = "A9876000Z"
    @transaction3.line_description = "Consent No - WXYZ/99/2/1"
    @transaction3.reference_1 = "WXYZ/99/2/1"
    @transaction3.tcm_financial_year = "1920"

    [@transaction1, @transaction2, @transaction3].each do |t|
      t.category = "2.3.4"
      t.status = "unbilled"
      t.tcm_charge = t.line_amount
      t.approved_for_billing = true
      apply_charge_calculation(t)
    end

    @exporter = TransactionFileExporter.new(@regime, @region, @user)
  end

  def test_export_creates_file_record
    assert_difference "TransactionFile.count" do
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
    @transaction2.update(approved_for_billing: false)
    @exporter.export

    file = TransactionFile.last
    assert_equal 2, file.transaction_details.count
    assert_includes file.transaction_details, @transaction1
    assert_not_includes file.transaction_details, @transaction2
    assert_includes file.transaction_details, @transaction3
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
    assert_difference "AuditLog.count" do
      @exporter.export
    end

    file = TransactionFile.last
    log = AuditLog.last
    assert_equal("create", log.action)
    assert_equal(file.audit_logs.last.id, log.id)
  end

  def test_export_includes_transactions_for_all_financial_years
    @exporter.export

    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count
    assert_includes file.transaction_details, @transaction1
    assert_includes file.transaction_details, @transaction2
    assert_includes file.transaction_details, @transaction3
  end

  def test_cfd_splits_transaction_references_by_financial_year
    @exporter.export

    file = TransactionFile.last
    file.transaction_details.update_all(customer_reference: "ABCD1234")
    @exporter.assign_cfd_transaction_references(file)
    assert_not_nil @transaction1.reload.tcm_transaction_reference
    assert_not_nil @transaction2.reload.tcm_transaction_reference
    assert_not_nil @transaction3.reload.tcm_transaction_reference

    assert_equal @transaction1.tcm_transaction_reference,
                 @transaction2.tcm_transaction_reference
    assert_not_equal @transaction1.tcm_transaction_reference,
                     @transaction3.tcm_transaction_reference
  end

  def test_cfd_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999")
    @transaction2.update(tcm_charge: @transaction1.tcm_charge,
                         customer_reference: "AABBCCDD")
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_cfd_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_cfd_splits_transaction_references_by_line_context_code
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999",
                                        line_context_code: "E")
    @transaction1.update(line_context_code: "A")

    # 1,2 and 3 same consent reference
    # 1 different context code
    # 3 different financial year
    @exporter.assign_cfd_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_financial_year
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234")
    @exporter.assign_wml_transaction_references(file)
    # 3 different references because split 1 invoice, 2 credit, 3 different FY
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999")
    @transaction2.update(tcm_charge: @transaction1.tcm_charge,
                         customer_reference: "AABBCCDD")
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_wml_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_wml_splits_transaction_references_by_credit_and_invoice
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999")
    # 1,2 and 3 same permit reference
    # 1 and 2 different credit/invoice
    # 3 different financial year
    @exporter.assign_wml_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_pas_assigns_transaction_references_correctly; end

  def test_pas_splits_transaction_references_by_financial_year
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234")
    @exporter.assign_pas_transaction_references(file)
    # 3 different references because split 1 invoice, 2 credit, 3 different FY
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_pas_splits_transaction_references_by_customer_reference
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999")
    @transaction2.update(tcm_charge: @transaction1.tcm_charge,
                         customer_reference: "AABBCCDD")
    # 1,2 and 3 same permit reference
    # 1 and 2 different customer reference
    # 3 different financial year
    @exporter.assign_pas_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def test_pas_splits_transaction_references_by_credit_and_invoice
    @exporter.export
    file = TransactionFile.last
    assert_equal 3, file.transaction_details.count

    file.transaction_details.update_all(customer_reference: "ABCD1234",
                                        reference_1: "ZZZZ9999")
    # 1,2 and 3 same permit reference
    # 1 and 2 different credit/invoice
    # 3 different financial year
    @exporter.assign_pas_transaction_references(file)
    assert_equal 3, file.transaction_details.distinct.pluck(:tcm_transaction_reference).count
  end

  def apply_charge_calculation(transaction)
    transaction.charge_calculation = {
      "calculation" => {
        "chargeAmount" => transaction.tcm_charge.abs,
        "decisionPoints" => {
          "baselineCharge" => 196_803,
          "percentageAdjustment" => 0
        }
      },
      "generatedAt" => "10-AUG-2017"
    }
    transaction.save!
  end
end
