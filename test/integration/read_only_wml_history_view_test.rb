require 'test_helper'

class ReadOnlyWmlHistoryViewTest < ActionDispatch::IntegrationTest
  include RegimeSetup, GenerateHistory

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    setup_wml_read_only
    generate_historic_wml
  end

  def test_no_csv_export_button
    visit regime_history_index_path(@regime)
    assert page.has_selector?("div.tcm-table table tbody tr", minimum: 1)
    assert page.has_no_selector?("button.table-export-btn"),
      "CSV export button found"
  end
end
