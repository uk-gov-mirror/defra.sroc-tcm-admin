require 'test_helper'

class SystemConfigTest < ActiveSupport::TestCase
  def test_start_import_sets_importing_flag
    SystemConfig.config.start_import
    assert SystemConfig.first.importing?
  end

  def test_start_import_returns_true_if_import_can_start
    assert SystemConfig.config.start_import
  end

  def test_start_import_returns_false_if_import_cannot_start
    SystemConfig.config.start_import
    refute SystemConfig.config.start_import
  end

  def test_stop_import_unsets_importing_flag
    SystemConfig.config.start_import
    SystemConfig.config.stop_import
    assert_equal false, SystemConfig.first.importing?
  end

  def test_stop_import_returns_true_if_importing
    SystemConfig.config.start_import
    assert SystemConfig.config.stop_import
  end

  def test_stop_import_returns_false_if_not_importing
    refute SystemConfig.config.stop_import
  end
end
