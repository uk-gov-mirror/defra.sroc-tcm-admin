require 'test_helper'

class ReadOnlyPasRetrospectivesViewTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    setup_pas_read_only
  end

  def test_no_generate_button
    visit regime_retrospectives_path(@regime)
    assert page.has_no_button?("Generate Pre-SRoC File"),
      "Generate button found"
  end

  def test_no_csv_export_button
    visit regime_retrospectives_path(@regime)
    assert page.has_selector?("div.tcm-table table tbody tr", minimum: 1)
    assert page.has_no_selector?("button.table-export-btn"),
      "CSV export button found"
  end
end
