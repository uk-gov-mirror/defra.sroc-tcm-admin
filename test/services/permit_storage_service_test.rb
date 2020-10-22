# frozen_string_literal: true

require "test_helper"

class PermitStorageServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @regime = regimes(:cfd)
    @user = users(:billing_admin)
    Thread.current[:current_user] = @user

    @service = PermitStorageService.new(@regime, @user)
  end

  def test_all_for_financial_year_returns_all_permits_for_the_financial_year
    pcs = @service.all_for_financial_year("1819")
    # not the same query but should be same result
    all = @regime.permit_categories.where(valid_from: "1819")

    assert_equal all, pcs
    pc = @regime.permit_categories.last
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "1920"
    pc2.description = "New version"
    pc.save!
    pc2.save!
    pcs2 = @service.all_for_financial_year("1920")
    assert_not_equal all, pcs2
    assert_not_includes pcs2, pc
    assert_includes pcs2, pc2
  end

  def test_all_for_financial_year_includes_excluded_categories
    pc = @regime.permit_categories.last
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "2021"
    pc2.status = "excluded"
    pc.save!
    pc2.save!
    q = @service.all_for_financial_year("1920")
    assert_includes q, pc
    assert_not_includes q, pc2
    q = @service.all_for_financial_year("2223")
    assert_includes q, pc2
    assert_not_includes q, pc
  end

  def test_active_for_financial_year_does_not_return_excluded_categories
    pc = @regime.permit_categories.last
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "2021"
    pc2.status = "excluded"
    pc.save!
    pc2.save!
    assert_includes @service.active_for_financial_year("1920"), pc
    assert_not_includes @service.active_for_financial_year("2223"), pc
    assert_not_includes @service.active_for_financial_year("2223"), pc2
  end

  def test_code_for_financial_year_does_not_return_excluded_categories
    pc = @regime.permit_categories.last
    code = pc.code
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "2021"
    pc2.status = "excluded"
    pc.save!
    pc2.save!
    assert_equal pc, @service.code_for_financial_year(code, "1819")
    assert_equal pc, @service.code_for_financial_year(code, "1920")
    assert_nil @service.code_for_financial_year(code, "2021")
    assert_nil @service.code_for_financial_year(code, "2122")
  end

  def test_code_for_financial_year_with_any_status_returns_excluded_categories
    pc = @regime.permit_categories.last
    code = pc.code
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "2021"
    pc2.status = "excluded"
    pc.save!
    pc2.save!
    assert_equal pc, @service.code_for_financial_year_with_any_status(code, "1819")
    assert_equal pc, @service.code_for_financial_year_with_any_status(code, "1920")
    assert_equal pc2, @service.code_for_financial_year_with_any_status(code, "2021")
    assert_equal pc2, @service.code_for_financial_year_with_any_status(code, "2122")
  end

  def test_permit_category_versions_returns_all_versions_of_a_code
    pc = @regime.permit_categories.last
    code = pc.code
    pc2 = pc.dup
    pc2.valid_from = pc.valid_to = "2021"
    pc2.status = "excluded"
    pc3 = pc2.dup
    pc3.valid_from = pc2.valid_to = "2425"
    pc3.status = "active"
    pc.save!
    pc2.save!
    pc3.save!

    q = @service.permit_category_versions(code)
    assert_equal [pc, pc2, pc3], q.to_a
  end

  def test_new_permit_category_creates_a_new_record
    pc = nil
    assert_difference "PermitCategory.count" do
      pc = @service.new_permit_category("9.8.7", "A new category", "1819")
    end
    assert_equal pc, PermitCategory.last
  end

  def test_new_permit_category_creates_excluded_record_when_future_date
    # when adding a new category from a financial year after 1819
    # we create an duplicate excluded record from 1819 to the requested
    # financial year.
    pc = nil
    assert_difference "PermitCategory.count", 2 do
      pc = @service.new_permit_category("9.8.7", "A new category", "2122")
    end
    assert_equal pc, PermitCategory.second_to_last
    pc2 = PermitCategory.last
    assert_equal pc.code, pc2.code
    assert_equal pc.description, pc2.description
    assert_equal "1819", pc2.valid_from
    assert_equal pc.valid_from, pc2.valid_to
    assert_equal pc2.status, "excluded"
  end

  def test_new_permit_category_returns_unsaved_object_if_invalid
    pc = nil
    assert_no_difference "PermitCategory.count" do
      pc = @service.new_permit_category("2.3.4", "An existing category",
                                        "1819")
    end
    assert_not_nil pc
    assert_not pc.persisted?
    assert pc.invalid?
  end

  def test_add_permit_category_version_creates_a_new_record
    pc = nil
    assert_difference "PermitCategory.count" do
      pc = @service.add_permit_category_version("2.3.4", "A new category version", "1920")
    end
    assert_equal pc, PermitCategory.last
  end

  def test_add_permit_category_version_updates_valid_to_in_previous_version
    pc = permit_categories(:cfd_a)
    assert_nil pc.valid_to

    @service.add_permit_category_version(pc.code, "A new category version", "1920")
    assert_equal "1920", pc.reload.valid_to
  end

  def test_add_permit_category_version_updates_valid_to_when_next_version_exists
    pc = permit_categories(:cfd_a)
    assert_nil pc.valid_to
    @service.add_permit_category_version(pc.code, "A later version", "2223")
    assert_equal "2223", pc.reload.valid_to

    pc3 = @service.add_permit_category_version(pc.code, "A between version", "1920")
    assert_equal "1920", pc.reload.valid_to
    assert_equal "2223", pc3.valid_to
  end

  def test_update_or_create_new_version_updates_description
    pc = permit_categories(:cfd_a)

    assert_no_difference "PermitCategory.count" do
      @service.update_or_create_new_version(pc.code, "Wigwam", pc.valid_from)
    end

    assert_equal "Wigwam", pc.reload.description
  end

  def test_update_or_create_new_version_creates_new_version
    pc = permit_categories(:cfd_a)
    old_desc = pc.description

    assert_difference "PermitCategory.count" do
      @service.update_or_create_new_version(pc.code, "Wigwam", "2223")
    end

    assert_equal old_desc, pc.reload.description
    assert_equal "Wigwam", PermitCategory.last.description
  end

  # def test_export_creates_audit_record
  #   assert_difference 'AuditLog.count' do
  #     @service.do_something
  #   end
  #
  #   permit = @regime.permit_categories.last
  #   log = AuditLog.last
  #   assert_equal('create', log.action)
  #   assert_equal(permit.audit_logs.last.id, log.id)
  # end
end
