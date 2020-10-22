# frozen_string_literal: true

require "test_helper"

class ReadOnlyPasExclusionsViewTest < ActionDispatch::IntegrationTest
  include RegimeSetup

  def setup
    Capybara.current_driver = Capybara.javascript_driver
    setup_pas_read_only
  end

  def test_no_csv_export_button
    visit regime_exclusions_path(@regime)
    assert page.has_selector?("div.tcm-table table tbody tr", minimum: 1)
    assert page.has_no_selector?("button.table-export-btn"),
           "CSV export button found"
  end
end
