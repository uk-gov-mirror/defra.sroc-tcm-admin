require 'test_helper.rb'

class CfdTransactionFilePresenterTest < ActiveSupport::TestCase
  def setup
    @transaction_1 = transaction_details(:cfd_charged_1)
    @transaction_2 = transaction_details(:cfd_charged_2)
    set_charge_calculation(@transaction_1)
    set_charge_calculation(@transaction_2)

    @file = transaction_files(:cfd_sroc_file)
    @file.transaction_details << @transaction_1
    @file.transaction_details << @transaction_2

    @presenter = CfdTransactionFilePresenter.new(@file)
  end

  def test_it_returns_a_header_record
    assert_equal(
      [
        "H",
        "0000000",
        "CFD",
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

  def test_detail_records_have_correct_line_attr_4_pro_rata_days
    @presenter.transaction_details.each_with_index do |td, i|
      p = CfdTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal(p.pro_rata_days, row[28])
    end
  end

  def test_detail_records_have_correct_temporary_cessation_value
    @presenter.transaction_details.each_with_index do |td, i|
      td.temporary_cessation = i.odd?
      expected_value = i.odd? ? '50%' : ''

      p = CfdTransactionDetailPresenter.new(td)
      row = @presenter.detail_row(p, i)
      assert_equal expected_value, row[32]
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

  def set_charge_calculation(transaction)
    transaction.charge_calculation = {
      'calculation' => {
        'chargeAmount' => transaction.tcm_charge.abs,
        'decisionPoints' => {
          'baselineCharge' => 196803
        }
      },
      'generatedAt' => '10-AUG-2017'
    }
    transaction.save
  end
end
