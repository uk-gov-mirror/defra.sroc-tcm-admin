# frozen_string_literal: true

require "test_helper"

class CfdCategoryProcessorTest < ActiveSupport::TestCase
  include GenerateHistory
  include ChargeCalculation
  def setup
    @regime = Regime.find_by(slug: "cfd")
    @header = transaction_headers(:cfd_annual)

    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::CfdCategoryProcessor.new(@header)
    build_mock_calculator
  end

  def test_fetch_unique_consents_returns_list_of_consent_references
    fixup_annual(@header)
    consents = @header.transaction_details.pluck(:reference_1).uniq.sort
    assert_equal consents, @processor.fetch_unique_consents
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_consent
    fixup_annual(@header)
    assert @processor.only_invoices_in_file?(reference_1: "AAAA/1/1")
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_consent
    fixup_annual(@header)
    refute @processor.only_invoices_in_file?(reference_1: "AAAF/2/3")
  end

  def test_find_latest_historic_invoice_returns_nil_when_no_matches_found
    fixup_annual(@header)
    assert_nil @processor.find_latest_historic_invoice(reference_1: "AAAB/1/1")
  end

  def test_find_latest_historic_invoice_returns_newest_matching_transaction
    fixup_annual(@header)
    # newest == newest period_end date
    historic = generate_historic_cfd
    arg = { reference_1: "AAAA/1/1" }
    assert_equal historic.first, @processor.find_latest_historic_invoice(arg)
  end

  def test_set_category_creates_suggested_category_record
    fixup_annual(@header)
    history = generate_historic_cfd
    matched = history.first
    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    assert_difference "SuggestedCategory.count" do
      @processor.set_category(transaction, matched, :amber, :stage_1)
    end
  end

  def test_set_category_sets_category
    fixup_annual(@header)
    history = generate_historic_cfd
    matched = history.first
    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    @processor.set_category(transaction, matched, :amber, :stage_2)
    assert_equal matched.category, transaction.reload.category
    assert_equal "Assigned matching category", transaction.suggested_category.logic
    assert transaction.suggested_category.amber?, "Confidence not AMBER"
  end

  def test_set_category_sets_matched_transaction
    fixup_annual(@header)
    history = generate_historic_cfd
    matched = history.first
    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    @processor.set_category(transaction, matched, :amber, :stage_3)
    assert_equal matched, transaction.suggested_category.matched_transaction, "Matched transaction incorrect"
  end

  def test_set_category_sets_charge_info
    fixup_annual(@header)
    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    history = generate_historic_cfd
    matched = history.first
    @processor.set_category(transaction, matched, :green, :stage_4)
    assert_not_nil transaction.charge_calculation
    assert_not_nil transaction.tcm_charge
  end

  def test_set_category_does_not_set_category_when_category_removed
    fixup_annual(@header)
    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    history = generate_historic_cfd
    matched = history.first
    p = PermitStorageService.new(@header.regime)
    p.update_or_create_new_version(matched.category, "test", "1920", "excluded")
    @processor.set_category(transaction, matched, :green, "Level x")
    sg = transaction.reload.suggested_category
    assert_not_nil sg.category
    assert_nil transaction.category
    assert_not_nil sg.matched_transaction
    assert_equal "Category not valid for financial year", sg.logic
    assert sg.red?, "Confidence not RED"
  end

  def test_set_category_does_not_set_category_if_calculation_error
    fixup_annual(@header)
    history = generate_historic_cfd
    matched = history.first
    build_mock_calculator_with_error
    # @calculator = build_mock_calculator_with_error
    # @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.find_by(reference_1: "AAAA/1/1")
    @processor.set_category(transaction, matched, :amber, "Level")
    sg = transaction.reload.suggested_category
    assert_not_nil sg.category
    assert_nil transaction.category
    assert_not_nil sg.matched_transaction
    assert_equal "Error assigning charge", sg.logic
    assert sg.red?, "Confidence not RED"
  end

  # Scenario 1 - Annual bill, no supplementary on permit since previous annual bill
  def test_suggest_categories_assigns_categories_from_last_annual_bill
    fixup_annual(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    history.each do |ht|
      t = @header.transaction_details.find_by(reference_1: ht.reference_1)
      assert_equal(ht.category, t.category)
      sg = t.suggested_category
      assert_equal("Assigned matching category", sg.logic)
      assert sg.green?
    end
  end

  # Scenario 2 & 4 - Annual bill, variation (category change) since previous AB
  def test_suggest_categories_assigns_categories_from_last_variation
    fixup_annual(@header)
    history = generate_historic_with_supplemental_cfd

    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: "AAAA/2/1")
    assert_equal(history.last.category, t.category)
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.green?
  end

  # Scenario 3 - Annual bill, new permit billed for the first time
  def test_suggest_categories_does_not_populate_category_for_new_permit
    fixup_annual(@header)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: "AAAB/1/1")
    assert_nil t.category
    sg = t.suggested_category
    assert_equal("No previous bill found", sg.logic)
    assert sg.red?, "Confidence not RED"
  end

  # Scenario 5 - Annual bill, variation (new discharge) since previous AB
  def test_suggest_categories_assigns_categories_from_last_variation_and_version
    fixup_annual(@header)
    history = generate_historic_with_supplemental_cfd
    history.last.update_attributes(category: "2.3.5")
    t = history.last.dup
    t.line_amount = 567_123
    t.reference_1 = "AAAA/2/2"
    t.reference_3 = "2"
    t.category = "2.3.6"
    t.save!
    history << t
    @processor.suggest_categories
    history.last(2).each do |ht|
      t = @header.transaction_details.find_by(reference_1: ht.reference_1)
      assert_equal(ht.category, t.category)
      sg = t.suggested_category
      assert_equal("Assigned matching category", sg.logic)
      assert sg.green?
    end
  end

  # Scenario 8 (new v3) Annual bill, in-year variation without revised charge incremented version
  def test_annual_bill_with_no_matches_retries_without_version
    fixup_annual(@header)
    history = generate_historic_cfd
    t2 = history.first.dup
    t2.customer_reference = "BB11"
    t2.reference_1 = "AAAG/1/1"
    t2.reference_2 = "1"
    t2.reference_3 = "1"
    t2.status = "billed"
    t2.line_amount = 18_724
    t2.category = "2.3.5"
    t2.tcm_financial_year = "2021"
    t2.period_start = "1-APR-2020"
    t2.period_end = "31-MAR-2021"
    t2.save!
    t3 = t2.dup
    t3.reference_1 = "AAAG/1/2"
    t3.reference_2 = "1"
    t3.reference_3 = "2"
    t3.line_amount = 4433
    t3.category = "2.3.6"
    t3.save!

    @processor.suggest_categories
    [t2, t3].each do |ht|
      t = @header.transaction_details.find_by(customer_reference: "BB11", reference_3: ht.reference_3)
      assert_equal(ht.category, t.category)
      sg = t.suggested_category
      assert_equal("Assigned matching category", sg.logic)
      assert sg.green?
    end
  end

  # Scenario 8 - Supplementary bill, permit category change, last bill was annual
  def test_supplemental_suggested_invoice_category_is_rated_green
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.first
    t = @header.transaction_details.invoices.find_by(reference_1: "AAAA/1/1")
    assert_equal(ht.category, t.category)
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.green?
    refute sg.admin_lock?, "Category locked"
  end

  def test_supplemental_suggested_versioned_invoice_category_is_rated_amber
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.first
    t = @header.transaction_details.invoices.find_by(reference_1: "AAAA/2/1")
    assert_equal(ht.category, t.category)
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.amber?, "Confidence not AMBER"
    refute sg.admin_lock?, "Category locked"
  end

  def test_supplemental_suggested_credit_category_is_rated_green_and_locked
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.first
    t = @header.transaction_details.credits.find_by(reference_1: "AAAA/1/1")
    assert_equal(ht.category, t.category)
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.green?
    assert sg.admin_lock?, "Category not locked"
  end

  # Scenario 9 - Supplementary bill, two discharges, permit category change on one,
  # last bill was annual

  # Scanario 10 - Supplementary bill, new discharge added, last bill was annual
  def test_supplemental_suggested_invoice_category_blank_for_new_discharge
    fixup_supplemental(@header)
    generate_historic_cfd
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: "AAAB/2/2")
    assert_nil t.category
    sg = t.suggested_category
    assert_equal("No previous bill found", sg.logic)
    assert sg.red?, "Confidence not RED"
    refute sg.admin_lock?, "Category locked"
  end

  def test_supplemental_suggested_invoice_new_version_rated_amber
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.select { |t| t.reference_1 == "AAAB/1/1" }.first
    t = @header.transaction_details.find_by(reference_1: "AAAB/2/1")
    assert_equal ht.category, t.category
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.amber?, "Confidence not AMBER"
    refute sg.admin_lock?, "Category locked"
  end

  # Scenario 14 - Supplementary bill, transfer of permit, last bill annual
  def test_supplemental_suggested_invoice_new_customer_rated_amber
    fixup_supplemental(@header)
    history = generate_historic_cfd
    @processor.suggest_categories
    ht = history.last
    t = @header.transaction_details.find_by(reference_1: "AAAC/1/1",
                                            customer_reference: "C9876")
    assert_equal ht.category, t.category
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert sg.amber?, "Confidence not AMBER"
    refute sg.admin_lock?, "Category locked"
  end

  def test_suggest_categories_generates_audit_records
    fixup_annual(@header)
    generate_historic_cfd
    audit_count_before = AuditLog.count
    @processor.suggest_categories
    audit_count_after = AuditLog.count
    count = @header.transaction_details.where.not(category: nil).count
    assert count.positive?
    assert_equal count, (audit_count_after - audit_count_before)
  end

  # defect 149 - Amber status given to supplemental invoice without matching end date
  def test_red_status_given_when_stage_2_end_date_does_not_match_defect_149
    transactions = fixup_defect_149(@header)
    @processor.suggest_categories

    transactions.each do |t|
      assert_nil t.category, "Category has been assigned for #{t.line_amount}"
      sg = t.suggested_category
      assert sg.red?, "Confidence not RED"
    end
  end

  def fixup_annual(header)
    t = transaction_details(:cfd_annual)
    [
      ["AAAA", "1", "1", 12_345, "A1234"],
      ["AAAA", "1", "2", 546_789, "A1234"],
      ["AAAA", "2", "1", 334_455, "A1234"],
      ["AAAA", "2", "2", 21_311, "A1234"],
      ["AAAB", "1", "1", 67_890, "A3453"],
      ["AAAC", "1", "1", 12_233, "A9483"],
      ["AAAD", "1", "1", 22_991, "A33133"],
      ["AAAE", "1", "1", 435_564, "A938392"],
      ["AAAE", "1", "2", 23_665, "A938392"],
      ["AAAF", "2", "3", 124_322, "A993022"],
      ["AAAF", "2", "3", -123_991, "A993022"],
      ["AAAG", "2", "1", 45_678, "BB11"],
      ["AAAG", "2", "2", 3456, "BB11"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0..2].join("/")
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = "1-APR-2019"
      tt.period_end = "31-MAR-2020"
      tt.tcm_financial_year = "1920"
      tt.save!
    end
  end

  def fixup_supplemental(header)
    t = transaction_details(:cfd_annual)
    [
      ["AAAA", "1", "1", -12_345, "A1234", "1-APR-2018", "31-MAR-2019"],
      ["AAAA", "1", "1", 6789, "A1234", "1-APR-2018", "30-JUN-2018"],
      ["AAAA", "2", "1", 334_455, "A1234", "1-JUL-2018", "31-MAR-2019"],
      ["AAAB", "1", "1", -34_560, "B1234", "1-APR-2018", "31-MAR-2019"],
      ["AAAB", "1", "1", 14_153, "B1234", "1-APR-2018", "30-JUN-2018"],
      ["AAAB", "2", "1", 20_407, "B1234", "1-JUL-2018", "31-MAR-2019"],
      ["AAAB", "2", "2", 33_992, "B1234", "1-JUL-2018", "31-MAR-2019"],
      ["AAAC", "1", "1", -34_560, "C1234", "1-APR-2018", "31-MAR-2019"],
      ["AAAC", "1", "1", 14_153, "C1234", "1-APR-2018", "30-JUN-2018"],
      ["AAAC", "1", "1", 20_407, "C9876", "1-JUL-2018", "31-MAR-2019"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0..2].join("/")
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = ref[5]
      tt.period_end = ref[6]
      tt.tcm_financial_year = "1819"
      tt.save!
    end
  end

  def fixup_defect_149(header)
    history = generate_historic_cfd
    t2 = history.second.dup
    t2.status = "unbilled"
    t2.line_amount = 18_724
    t2.category = nil
    t2.transaction_header_id = header.id
    t2.tcm_financial_year = "1920"
    t2.period_start = "21-MAY-2019"
    t2.period_end = "05-AUG-2020"
    t2.transaction_file_id = nil
    t2.save!
    t3 = t2.dup
    t3.status = "unbilled"
    t3.line_amount = 58_117
    t3.category = nil
    t3.transaction_header_id = header.id
    t3.tcm_financial_year = "1920"
    t3.period_start = "06-AUG-2019"
    t3.period_end = "31-MAR-2020"
    t3.transaction_file_id = nil
    t3.save!
    t4 = t2.dup
    t4.status = "unbilled"
    t4.line_amount = -76_841
    t4.category = nil
    t4.transaction_header_id = header.id
    t4.tcm_financial_year = "1920"
    t4.period_start = "21-MAY-2019"
    t4.period_end = "31-MAR-2020"
    t4.transaction_file_id = nil
    t4.save!
    [t2, t3, t4]
  end
end
