# frozen_string_literal: true

require "test_helper"

class WmlCategoryProcessorTest < ActiveSupport::TestCase
  include GenerateHistory
  include ChargeCalculation

  def setup
    @header = transaction_headers(:wml_annual)
    @transactions = fixup_transactions(@header)

    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::WmlCategoryProcessor.new(@header)
    build_mock_calculator
    @header.regime.permit_categories.create!(code: "2.15.3",
                                             description: "test",
                                             status: "active")
  end

  def test_fetch_unique_consents_returns_list_of_consent_references
    consents = @header.transaction_details.pluck(:reference_1).uniq.sort
    assert_equal consents, @processor.fetch_unique_consents
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_permit
    assert @processor.only_invoices_in_file?(reference_1: "0123456")
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_permit
    refute @processor.only_invoices_in_file?(reference_1: "0123451")
  end

  def test_find_latest_historic_transaction_returns_nil_when_no_matches_found
    assert_nil @processor.find_latest_historic_transaction(
      reference_1: "0123456", reference_3: "1"
    )
  end

  def test_find_historic_transaction_returns_newest_matching_transaction
    # newest == newest period_end date
    historic = generate_historic_wml
    assert_equal historic[1], @processor.find_latest_historic_transaction(
      reference_1: "0123456", reference_3: "1"
    )
  end

  def test_set_category_sets_category
    history = generate_historic_wml
    matched = history.last
    transaction = @header.transaction_details.find_by(reference_1: "0123456")
    @processor.set_category(transaction, matched, :green, "Level")
    assert_equal matched.category, transaction.reload.category
    sg = transaction.suggested_category
    assert_equal "Assigned matching category", sg.logic
    assert sg.green?
  end

  def test_set_category_sets_charge_info
    history = generate_historic_wml
    matched = history.last
    transaction = @header.transaction_details.find_by(reference_1: "0123456")
    @processor.set_category(transaction, matched, :amber, "Level")
    assert_not_nil transaction.charge_calculation
    assert_not_nil transaction.tcm_charge
  end

  def test_set_category_does_not_set_category_when_category_removed
    history = generate_historic_wml
    matched = history.last
    matched.category = "2.3.9"
    transaction = @header.transaction_details.find_by(reference_1: "0123456")
    @processor.set_category(transaction, matched, :green, "Level")
    assert_nil transaction.reload.category
    sg = transaction.suggested_category
    assert_equal "Category not valid for financial year", sg.logic
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_set_category_does_not_set_category_if_calculation_error
    history = generate_historic_wml
    matched = history.last
    build_mock_calculator_with_error
    # @calculator = build_mock_calculator_with_error
    # @processor.stubs(:calculator).returns(@calculator)

    transaction = @header.transaction_details.find_by(reference_1: "0123456")
    @processor.set_category(transaction, matched, :green, "Level")
    assert_nil transaction.reload.category
    sg = transaction.suggested_category
    assert_equal "Error assigning charge", sg.logic
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_suggest_categories_processes_transactions_in_file
    generate_historic_wml
    @processor.suggest_categories

    [
      ["0123456", "1", "2.15.3", "Assigned matching category"],
      ["0123457", "1", nil, "No previous bill found"],
      ["0123458", "1", nil, "No previous bill found"],
      ["0123459", "1", nil, "No previous bill found"],
      ["0123450", "1", nil, "No previous bill found"],
      ["0123450", "2", nil, "No previous bill found"],
      ["0123451", "1", nil, "No previous bill found"],
      ["0123451", "2", nil, "No previous bill found"]
    ].each do |td|
      t = @header.transaction_details.find_by(reference_1: td[0],
                                              reference_3: td[1])
      assert_not_nil t, "Didnt find #{td[0]},#{td[1]}"
      if td[2].nil?
        assert_nil t.category, "Failed category #{td[0]}"
      else
        assert_equal td[2], t.category, "Failed category #{td[0]}"
      end
      sg = t.suggested_category
      assert_equal td[3], sg.logic, "Failed logic #{td[0]}"
    end
  end

  def test_suggest_categories_does_not_consider_historic_credits
    historic = generate_historic_wml
    historic.last.update(line_amount: -1234)
    @processor.suggest_categories
    t = @header.transaction_details.find_by(reference_1: "0123456", reference_3: "1")
    assert_equal("2.15.2", t.category)
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
  end

  def test_suggest_categories_generates_audit_records
    generate_historic_wml
    audit_before = AuditLog.count
    @processor.suggest_categories
    audit_after = AuditLog.count
    count = @header.transaction_details.where.not(category: nil).count
    assert_equal count, (audit_after - audit_before)
  end

  def test_supplemental_no_suggestion_when_more_than_one_invoice
    generate_historic_wml

    t = @transactions.second_to_last.dup
    t.line_amount = 123_000
    t.save!

    @processor.suggest_categories

    assert_nil t.reload.category, "Category set!"
    sg = t.suggested_category
    assert_equal("Multiple activities for permit", sg.logic)
    assert_equal("Supplementary invoice stage 1", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_supplemental_invoice_no_suggestion_when_no_history
    @processor.suggest_categories

    t = @transactions.second_to_last.reload

    assert_nil t.category, "Category set!"
    sg = t.suggested_category
    assert_equal("No previous bill found", sg.logic)
    assert_equal("Supplementary invoice stage 1", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_supplemental_invoice_amber_suggestion_when_single_match
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!

    @processor.suggest_categories

    t = @transactions.second_to_last.reload

    assert_equal ht.category, t.category, "Category not equal"
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert_equal("Supplementary invoice stage 1", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.amber?
  end

  def test_supplemental_invoice_amber_suggestion_when_multiple_match
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!
    ht2 = ht.dup
    ht2.period_start = "30-SEP-2020"
    ht2.category = "2.15.2"
    ht2.save!

    @processor.suggest_categories

    t = @transactions.second_to_last.reload

    assert_equal ht.category, t.category, "Category not equal"
    assert ht2.category != t.category, "Second category is equal"
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert_equal("Supplementary invoice stage 2", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.amber?
  end

  def test_supplemental_invoice_red_suggestion_when_multiple_matching_dates
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!
    ht2 = ht.dup
    ht2.category = "2.15.2"
    ht2.save!

    @processor.suggest_categories

    t = @transactions.second_to_last.reload

    assert_nil t.category, "Category set!"
    sg = t.suggested_category
    assert_equal("Multiple historic matches found", sg.logic)
    assert_equal("Supplementary invoice stage 2", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_supplemental_credit_green_suggestion_when_single_match
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!

    @processor.suggest_categories

    t = @transactions.last.reload

    assert_equal ht.category, t.category, "Category not equal"
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert_equal("Supplementary credit stage 1", sg.suggestion_stage)
    assert sg.admin_lock?, "Not admin locked"
    assert sg.green?
  end

  def test_supplemental_credit_green_suggestion_when_multiple_match
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!
    ht2 = ht.dup
    ht2.period_start = "30-SEP-2020"
    ht2.category = "2.15.2"
    ht2.save!

    @processor.suggest_categories

    t = @transactions.last.reload

    assert_equal ht.category, t.category, "Category not equal"
    assert ht2.category != t.category, "Second category is equal"
    sg = t.suggested_category
    assert_equal("Assigned matching category", sg.logic)
    assert_equal("Supplementary credit stage 2", sg.suggestion_stage)
    assert sg.admin_lock?, "Not admin locked"
    assert sg.green?
  end

  def test_supplemental_credit_red_suggestion_when_multiple_matching_dates
    historic = generate_historic_wml
    ht = historic.last.dup
    ht.reference_1 = "0123451"
    ht.reference_2 = "E1239"
    ht.reference_3 = "1"
    ht.period_start = "1-JAN-2021"
    ht.period_end = "31-MAR-2021"
    ht.save!
    ht2 = ht.dup
    ht2.category = "2.15.2"
    ht2.save!

    @processor.suggest_categories

    t = @transactions.last.reload

    assert_nil t.category, "Category set!"
    sg = t.suggested_category
    assert_equal("Multiple historic matches found", sg.logic)
    assert_equal("Supplementary credit stage 2", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_supplemental_no_suggestion_when_more_than_one_credit
    generate_historic_wml

    t = @transactions.last.dup
    t.line_amount = -123_000
    t.save!

    @processor.suggest_categories

    assert_nil t.reload.category, "Category set!"
    sg = t.suggested_category
    assert_equal("Multiple activities for permit", sg.logic)
    assert_equal("Supplementary credit stage 1", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def test_supplemental_credit_no_suggestion_when_no_history
    @processor.suggest_categories

    t = @transactions.last.reload

    assert_nil t.category, "Category set!"
    sg = t.suggested_category
    assert_equal("No previous bill found", sg.logic)
    assert_equal("Supplementary credit stage 1", sg.suggestion_stage)
    refute sg.admin_lock?, "It is admin locked"
    assert sg.red?
  end

  def fixup_transactions(header)
    results = []
    t = transaction_details(:wml_annual)
    [
      ["0123456", "E1234", "1", 12_345, "A1234"],
      ["0123457", "E1235", "1", 67_890, "A3453"],
      ["0123458", "E1236", "1", 12_233, "A9483"],
      ["0123459", "E1237", "1", 22_991, "A33133"],
      ["0123450", "E1238", "1", 435_564, "A938392"],
      ["0123450", "E1238", "2", 23_665, "A938392"],
      ["0123451", "E1239", "1", 124_322, "A993022"],
      ["0123451", "E1239", "2", -123_991, "A993022"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0]
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.period_start = "1-APR-2020"
      tt.period_end = "31-MAR-2021"
      tt.tcm_financial_year = "2021"
      tt.save!
      results << tt
    end
    results
  end
end
