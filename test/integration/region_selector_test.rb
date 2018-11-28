require 'test_helper'

class RegionSelectorTest < ActionDispatch::IntegrationTest
  def setup
    Capybara.current_driver = Capybara.javascript_driver
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    @regions_only = @regime.transaction_headers.distinct.pluck(:region).sort
    @regions_with_all = [ 'All' ] + @regions_only
    sign_in @user
  end

  def test_can_see_region_selector_on_ttbb_without_all_option
    visit regime_transactions_path(@regime)
    assert page.has_select? "region", options: @regions_only
  end

  def test_can_see_region_selector_on_history_with_all_option
    visit regime_history_index_path(@regime)
    assert page.has_select? "region", options: @regions_with_all
  end

  def test_can_select_all_region_option_on_history
    visit regime_history_index_path(@regime)

    # select a region
    @regions_only.each do |r|
      page.select(r, from: 'region')
      row_count = @regime.transaction_details.region(r).historic.count
      page.find(".tcm-table") do |t|
        # does region select have correct region selected?
        assert t.has_select?('region', selected: r),
          "'#{r}' option not selected"
        t.find("table>tbody") do |body|
          body.assert_selector("tr", count: row_count)
        end
      end
    end

    # select all regions
    page.select('All', from: 'region')
    row_count = @regime.transaction_details.historic.count
    page.find(".tcm-table") do |t|
      # does region select have 'All' selected?
      assert t.has_select?('region', selected: 'All'),
        "All option not selected"

      t.find("table>tbody") do |body|
        body.assert_selector("tr", count: row_count)
      end
    end
    # page.select('All', from: 'region')
    # page.find("#region>option[value='A']").click
    # row_count = @regime.transaction_details.unbilled.count
    # assert row_count.positive?
    # page.find(".tcm-table>table>tbody") do |body|
    #   body.assert_selector("tr", count: row_count)
    # end
    # page.assert_selector(".tcm-table>table>tbody>tr", count: row_count)
  end

  def test_can_see_region_selector_on_retrospective_with_all_option
    visit regime_retrospectives_path(@regime)
    assert page.has_select? "region", options: @regions_with_all
  end

  def test_can_see_region_selector_on_exclusions_with_all_option
    visit regime_exclusions_path(@regime)
    assert page.has_select? "region", options: @regions_with_all
  end
end
