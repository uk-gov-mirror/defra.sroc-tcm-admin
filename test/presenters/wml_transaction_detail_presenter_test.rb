require 'test_helper.rb'

class WmlTransactionDetailPresenterTest < ActiveSupport::TestCase
  def setup
    @transaction = transaction_details(:pas)
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

  def test_it_returns_permit_reference
    assert_equal(@transaction.reference_1, @presenter.permit_reference)
  end

  def test_it_transforms_into_json
    assert_equal(@presenter.as_json, {
      id: @transaction.id,
      customer_reference: @presenter.customer_reference,
      permit_reference: @presenter.permit_reference,
      compliance_band: @presenter.compliance_band,
      sroc_category: @presenter.category,
      temporary_cessation: @presenter.temporary_cessation_flag,
      period: @presenter.period,
      amount: @presenter.amount
    })
  end
end
