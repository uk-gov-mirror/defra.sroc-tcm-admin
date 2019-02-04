require 'test_helper'

class HistoryExportTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    setup_cfd
  end

  def test_view_should_have_export_button
    visit regime_history_index_path(@regime)
    assert page.has_selector? "button.table-export-btn"
  end

  def test_export_button_should_display_data_protection_notice
    visit regime_history_index_path(@regime)
    page.click_button "Export matching entries"
    page.find("#data-protection-dialog", visible: true) do |dlg|
      assert dlg.has_text? "Data Protection Notice"
    end
  end
end


