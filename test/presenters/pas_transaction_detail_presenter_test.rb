require 'test_helper.rb'

class PasTransactionDetailPresenterTest < ActiveSupport::TestCase
  def setup
    set_audit_user
    @transaction = transaction_details(:pas)
    @presenter = PasTransactionDetailPresenter.new(@transaction)
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
    band = @transaction.line_attr_11
    band = band.present? ? band.first : ""
    assert_equal(band, @presenter.compliance_band)
  end

  def test_it_returns_calculated_compliance_adjustment
    set_charge_calculation_compliance(@transaction, "A (110%)")
    assert_equal("110%", @presenter.compliance_band_adjustment)
  end

  def test_it_returns_permit_reference
    assert_equal(@transaction.reference_1, @presenter.permit_reference)
  end

  def test_it_returns_original_permit_reference
    assert_equal(@transaction.reference_2, @presenter.original_permit_reference)
  end

  def test_it_returns_site
    assert_equal(@transaction.header_attr_3, @presenter.site)
  end

  def test_it_builds_site_address
    @transaction.header_attr_8 = 'AB12 1AB'
    addr = "Site: Red St. Hill Farm, , , , ,AB12 1AB"
    assert_equal(addr, @presenter.site_address)
  end

  def test_it_transforms_into_json
    assert_equal(
      {
        id: @transaction.id,
        customer_reference: @presenter.customer_reference,
        tcm_transaction_reference: @presenter.tcm_transaction_reference,
        generated_filename: @presenter.generated_filename,
        original_filename: @presenter.original_filename,
        original_file_date: @presenter.original_file_date_table,
        permit_reference: @presenter.permit_reference,
        original_permit_reference: @presenter.original_permit_reference,
        compliance_band: @presenter.compliance_band,
        site: @presenter.site,
        sroc_category: @presenter.category,
        temporary_cessation: @presenter.temporary_cessation_flag,
        financial_year: @presenter.charge_period,
        region: @presenter.region_from_ref,
        period: @presenter.period,
        line_amount: @presenter.original_charge,
        amount: @presenter.amount,
        excluded: @presenter.excluded,
        excluded_reason: @presenter.excluded_reason,
        error_message: @presenter.error_message
      },
      @presenter.as_json
    )
  end

  def set_charge_calculation_compliance(transaction, band)
    transaction.charge_calculation = {
      "calculation": {
        "compliancePerformanceBand": band
      }
    }
    transaction.save!
  end
end
