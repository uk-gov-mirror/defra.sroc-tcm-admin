require 'test_helper.rb'

class CfdTransactionDetailPresenterTest < ActiveSupport::TestCase
  def setup
    @transaction = transaction_details(:cfd)
    @presenter = CfdTransactionDetailPresenter.new(@transaction)
  end

  def test_it_returns_charge_params
    assert_equal(
      {
        permitCategoryRef: @transaction.category,
        percentageAdjustment: clean_variation,
        temporaryCessation: @presenter.temporary_cessation,
        compliancePerformanceBand: 'B',
        billableDays: billable_days,
        financialDays: financial_year_days,
        chargePeriod: charge_period,
        preConstruction: false,
        environmentFlag: 'TEST'
      },
      @presenter.charge_params
    )
  end

  def test_it_returns_discharge_description
    assert_equal(@presenter.discharge_description, @transaction.line_attr_2)
  end

  def test_it_returns_site
    assert_equal(@presenter.site, @transaction.line_attr_1)
  end

  def test_it_returns_billable_days
    assert_equal(@presenter.billable_days, billable_days)
  end

  def test_it_returns_financial_year_days
    assert_equal(@presenter.financial_year_days, financial_year_days)
  end

  def test_it_returns_financial_year
    assert_equal(@presenter.financial_year, financial_year)
  end

  def test_it_returns_charge_period
    assert_equal(@presenter.charge_period, charge_period)
  end

  def test_it_returns_clean_variation_percentage
    assert_equal(@presenter.clean_variation_percentage, clean_variation)
  end

  def test_it_returns_variation_percentage
    assert_equal(@presenter.variation_percentage, @transaction.line_attr_9)
  end

  def test_it_returns_consent_reference
    assert_equal(@presenter.consent_reference, @transaction.reference_1)
  end

  def test_it_returns_permit_reference
    assert_equal(@presenter.permit_reference, @transaction.reference_1)
  end

  def test_it_returns_a_version
    assert_equal(@presenter.version, @transaction.reference_2)
  end

  def test_it_returns_a_discharge_reference
    assert_equal(@presenter.discharge_reference, @transaction.reference_3)
  end

  def test_it_transforms_into_json
    assert_equal(@presenter.as_json, {
      id: @transaction.id,
      customer_reference: @presenter.customer_reference,
      tcm_transaction_reference: @presenter.tcm_transaction_reference,
      generated_filename: @presenter.generated_filename,
      original_filename: @presenter.original_filename,
      original_file_date: @presenter.original_file_date,
      consent_reference: @presenter.consent_reference,
      version: @presenter.version,
      discharge: @presenter.discharge_reference,
      sroc_category: @presenter.category,
      variation: @presenter.clean_variation_percentage,
      temporary_cessation: @presenter.temporary_cessation_flag,
      financial_year: @presenter.charge_period,
      region: @presenter.region_from_ref,
      period: @presenter.period,
      amount: @presenter.amount
    })
  end

  def clean_variation
    v = @transaction.variation || @transaction.line_attr_9
    return 100 if v.blank?
    v.gsub(/%/, '')
  end

  def financial_year_days
    year = financial_year
    start_date = Date.new(year, 4, 1) # 1st April
    end_date = Date.new(year + 1, 3 ,31) # 31st March
    (end_date - start_date).to_i + 1
  end

  def billable_days
    (@transaction.period_end.to_date - @transaction.period_start.to_date).to_i + 1
  end

  def financial_year
    @transaction.period_start.month < 4 ? @transaction.period_start.year + 1 : @transaction.period_start.year
  end

  def charge_period
    "FY#{@transaction.tcm_financial_year}"
  end
end
