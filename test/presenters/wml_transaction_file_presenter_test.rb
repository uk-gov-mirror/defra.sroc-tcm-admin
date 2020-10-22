# frozen_string_literal: true

require "test_helper"

class WmlTransactionFilePresenterTest < ActiveSupport::TestCase
  include TransactionFileFormat

  def setup
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @transaction1 = transaction_details(:wml)
    @transaction2 = @transaction1.dup

    @transaction2.customer_reference = "A223344123P"
    @transaction2.transaction_reference = "E00555123"
    @transaction2.transaction_type = "C"
    @transaction2.line_attr_2 = "012345"
    @transaction2.reference_1 = "012345"
    @transaction2.reference_2 = "XZ3333PG/A001"
    @transaction2.line_amount = -1234
    @transaction2.unit_of_measure_price = -1234

    @transaction3 = transaction_details(:wml_invoice)

    [@transaction1, @transaction2, @transaction3].each_with_index do |t, i|
      t.category = "2.4.4"
      t.status = "billed"
      t.tcm_charge = t.line_amount
      t.tcm_transaction_type = t.transaction_type
      t.tcm_transaction_reference = generate_reference(t, 100 - i)
      apply_charge_calculation(t, "A(#{rand(50..100)}%)")
    end

    @file = transaction_files(:wml_sroc_file)
    @file.transaction_details << @transaction1
    @file.transaction_details << @transaction2
    @file.transaction_details << @transaction3

    @presenter = WmlTransactionFilePresenter.new(@file)
  end

  def test_it_returns_a_header_record
    assert_equal(
      [
        "H",
        "0000000",
        "WML",
        "B",
        "I",
        @file.file_id,
        "",
        @file.generated_at.strftime("%-d-%^b-%Y")
      ],
      @presenter.header
    )
  end

  def test_it_produces_detail_records
    rows = []
    @presenter.details do |row|
      rows << row
    end
    assert_equal(3, rows.count)
  end

  def test_it_sorts_detail_rows_by_tcm_transaction_reference
    rows = []
    @presenter.details do |row|
      rows << row
    end
    sorted_rows = [@transaction1, @transaction2, @transaction3].sort do |a, b|
      a.tcm_transaction_reference <=> b.tcm_transaction_reference
    end

    rows.each_with_index do |r, i|
      assert_equal(sorted_rows[i].tcm_transaction_reference, r[Detail::TransactionReference])
    end
  end

  def test_detail_record_has_correct_category_description
    expected_value = "Wigwam"
    tested = false
    @presenter.transaction_details.each_with_index do |td, i|
      next unless td.invoice?

      td.category_description = expected_value

      p = WmlTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[Detail::LineAttr5]
      tested = true
    end
    assert tested, "Did not test an invoice for category_description"
  end

  def test_is_returns_a_trailer_record
    count = @presenter.transaction_details.count
    assert_equal(
      [
        "T",
        (count + 1).to_s.rjust(7, "0"),
        (count + 2).to_s.rjust(7, "0"),
        @presenter.transaction_details.where(tcm_transaction_type: "I").sum(:tcm_charge).to_i,
        @presenter.transaction_details.where(tcm_transaction_type: "C").sum(:tcm_charge).to_i
      ],
      @presenter.trailer
    )
  end

  def apply_charge_calculation(transaction, band)
    transaction.charge_calculation = {
      "calculation" => {
        "chargeAmount" => transaction.tcm_charge.abs,
        "compliancePerformanceBand" => band,
        "decisionPoints" => {
          "baselineCharge" => 196_803,
          "percentageAdjustment" => 0
        }
      },
      "generatedAt" => "10-AUG-2017"
    }
    transaction.save!
  end

  def generate_reference(transaction, num)
    "WML#{num.to_s.rjust(8, '0')}#{transaction.transaction_header.region}T"
  end
end
