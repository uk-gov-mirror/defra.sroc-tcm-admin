require 'test_helper.rb'

class WmlTransactionDetailPresenterTest < ActiveSupport::TestCase
  def setup
    @transaction = transaction_details(:wml)
    @presenter = WmlTransactionDetailPresenter.new(@transaction)
  end

  # def test_it_returns_charge_params
  #   assert_equal(@presenter.charge_params, {
  #     permitCategoryRef: @transaction.category,
  #     percentageAdjustment: clean_variation,
  #     temporaryCessation: false,
  #     compliancePerformanceBand: 'B',
  #     billableDays: billable_days,
  #     financialDays: financial_year_days,
  #     chargePeriod: charge_period,
  #     preConstruction: false,
  #     environmentFlag: 'TEST'
  #   })
  # end
  #
  def test_it_returns_compliance_band
    band = @transaction.line_attr_6
    band = band.present? ? band.first : ""
    assert_equal(band, @presenter.compliance_band)
  end

  def test_credit_line_description_modifies_the_line_description
    @presenter.category = "2.15.2"
    val = "Credit of subsistence charge for permit category 2.15.2 due to the "\
      "licence being surrendered.wef 6/3/2018 at Hairy Wigwam, Big Pig Farm, "\
      "Great Upperford, Big Town, BT5 5EL, EPR Ref: XZ3333PG/A001"
    assert_equal(val, @presenter.credit_line_description)
  end

  def test_invoice_line_description_modifies_the_line_description
    transaction = transaction_details(:wml_invoice)
    presenter = WmlTransactionDetailPresenter.new(transaction)

    val = "Site: Hairy Wigwam, Big Pig Farm, Great Upperford, Big Town, BT5 5EL, "\
      "EPR Ref: XZ3333PG/A001"
    assert_equal(val, presenter.invoice_line_description)
  end

  def test_it_returns_permit_reference
    assert_equal(@transaction.reference_1, @presenter.permit_reference)
  end

  def test_it_transforms_into_json
    assert_equal({
      id: @transaction.id,
      customer_reference: @presenter.customer_reference,
      tcm_transaction_reference: @presenter.tcm_transaction_reference,
      generated_filename: @presenter.generated_filename,
      original_filename: @presenter.original_filename,
      original_file_date: @presenter.original_file_date_table,
      permit_reference: @presenter.permit_reference,
      compliance_band: @presenter.compliance_band,
      sroc_category: @presenter.category,
      temporary_cessation: @presenter.temporary_cessation_flag,
      period: @presenter.period,
      amount: @presenter.amount,
      error_message: nil
    }, @presenter.as_json)
  end
end
