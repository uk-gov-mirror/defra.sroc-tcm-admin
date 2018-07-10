require 'test_helper.rb'

class PasTransactionFilePresenterTest < ActiveSupport::TestCase
  include TransactionFileFormat

  def setup
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @transaction_1 = transaction_details(:pas)
    @transaction_2 = @transaction_1.dup

    @transaction_2.customer_reference ='A223344123P'
    @transaction_2.transaction_reference ='PAS00055512Y'
    @transaction_2.transaction_type = 'C'
    @transaction_2.reference_1 = 'VP1234AA'
    @transaction_2.line_amount = -1234
    @transaction_2.unit_of_measure_price = -1234

    [@transaction_1, @transaction_2].each_with_index do |t, i|
      t.category = '2.4.4'
      t.status = 'billed'
      t.tcm_charge = t.line_amount
      t.tcm_transaction_type = t.transaction_type
      t.tcm_transaction_reference = generate_reference(t, 100 - i)
      set_charge_calculation(t, "A(#{rand(50..100)}%)")
    end

    @file = transaction_files(:pas_sroc_file)
    @file.transaction_details << @transaction_1
    @file.transaction_details << @transaction_2

    @presenter = PasTransactionFilePresenter.new(@file)
  end

  def test_it_returns_a_header_record
    assert_equal(
      [
        "H",
        "0000000",
        "PAS",
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
    assert_equal(2, rows.count)
  end

  def test_it_sorts_detail_rows_by_tcm_transaction_reference
    rows = []
    @presenter.details do |row|
      rows << row
    end
    sorted_rows = [@transaction_1, @transaction_2].sort do |a,b|
      a.tcm_transaction_reference <=> b.tcm_transaction_reference
    end

    rows.each_with_index do |r, i|
      assert_equal(sorted_rows[i].tcm_transaction_reference, r[Detail::TransactionReference])
    end
  end

  def test_line_description_is_site_address
    @presenter.transaction_details.each_with_index do |td, i|
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal(p.site_address, row[Detail::LineDescription])
    end
  end

  def test_detail_records_transaction_type_is_same_as_source_record
    @presenter.transaction_details.each_with_index do |td, i|
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal(p.transaction_type, row[Detail::TransactionType])
    end
  end

  def test_detail_records_have_correct_line_attr_4_pro_rata_days
    @presenter.transaction_details.each_with_index do |td, i|
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal(p.pro_rata_days, row[Detail::LineAttr4])
    end
  end

  def test_detail_records_have_correct_temporary_cessation_value
    @presenter.transaction_details.each_with_index do |td, i|
      td.temporary_cessation = i.odd?
      expected_value = i.odd? ? '50%' : ''

      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[Detail::LineAttr12]
    end
  end

  def test_detail_record_has_correct_transaction_date
    expected_value = @file.generated_at.strftime("%d-%^b-%Y") # DD-MMM-YYYY format
    @presenter.transaction_details.each_with_index do |td, i|
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[Detail::TransactionDate]
      assert_equal expected_value, row[Detail::HeaderAttr1]
    end
  end

  def test_detail_record_permit_reference_not_prefixed
    # permit ref. shouldn't be prefixed with original text
    @presenter.transaction_details.each_with_index do |td, i|
      expected_value = td.reference_1
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[Detail::LineAttr1]
    end
  end

  def test_detail_record_includes_percentage_adjustment
    @presenter.transaction_details.each_with_index do |td, i|
      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal p.compliance_band_adjustment, row[Detail::LineAttr8]
    end
  end

  def test_detail_record_has_correct_category_description
    expected_value = 'Wigwam'
    @presenter.transaction_details.each_with_index do |td, i|
      td.category_description = expected_value

      p = PasTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[Detail::LineAttr5]
    end
  end

  def test_is_returns_a_trailer_record
    count = @presenter.transaction_details.count
    assert_equal(
      [
        "T",
        (count + 1).to_s.rjust(7, '0'),
        (count + 2).to_s.rjust(7, '0'),
        @presenter.transaction_details.where(tcm_transaction_type: 'I').sum(:tcm_charge).to_i,
        @presenter.transaction_details.where(tcm_transaction_type: 'C').sum(:tcm_charge).to_i
      ],
      @presenter.trailer
    )
  end

  def set_charge_calculation(transaction, band)
    transaction.charge_calculation = {
      'calculation' => {
        'chargeAmount' => transaction.tcm_charge.abs,
        'compliancePerformanceBand' => band,
        'decisionPoints' => {
          'baselineCharge' => 196803,
          'percentageAdjustment' => 0
        }
      },
      'generatedAt' => '10-AUG-2017'
    }
    transaction.save!
  end

  def generate_reference(transaction, num)
    "PAS#{num.to_s.rjust(8, '0')}#{transaction.transaction_header.region}T"
  end
end
