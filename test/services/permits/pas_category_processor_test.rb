require 'test_helper.rb'

# Tests for:
# Annual Billing:
#   Single permit - Stage 1
#     Match 1 (green)
#     Multiple matches (red)
#   Single permit - Stage 2 (ignores customer_reference)
#     Match 1 (green)
#     Multiple matches (red)
#     No matches (red)
#   Mutliple permits - Stage 1
#     Match same number (amber)
#     Multiple matches (red)
#   Multiple permits - Stage 2 (ignores customer_reference)
#     Match same number (amber)
#     Multiple matches (red)
#     No matches (red)
# Supplementary Billing:
#   Debits:
#     Single debit - Stage 1
#       Match 1 (green)
#       Multiple matches (only one most recent period start) (amber)
#       Mutliple matches (no single recent) (red)
#     Single debit - Stage 2 (ignores customer reference)
#       Match 1 (green)
#       Multiple matches (only one most recent period start) (amber)
#       Mutliple matches (no single recent) (red)
#       No matches (red)
#     Multiple debits - Stage 1
#       Match all (amber)
#     Multiple debits - Stage 2 (ignores customer reference)
#       Match all (amber)
#       No matches (red)
#     Mutliple debits - Stage 3
#       Match all when using most recent period start (amber)
#       Doesnt match all when using most recent period start (red)
#     Multiple debits - Stage 4 (ignores customer reference)
#       Match all when using most recent period start (amber)
#       Doesnt match all when using most recent period start (red)
#   Credits:
#     Single credit - Stage 1/2
#       Match 1 (green)
#       Multiple matches (only one most recent period start) (amber)
#       Mutliple matches (no single recent) (red)
#       No matches (red)
#     Multiple credits - Stage 1
#       Match all (amber)
#       No matches (red)
#     Mutliple credits - Stage 2
#       Match all when using most recent period start (amber)
#       Doesnt match all when using most recent period start (red)

# valid category fixtures for 2.4.4, 2.4.5 and 2.4.6
#
class PasCategoryProcessorTest < ActiveSupport::TestCase
  include ChargeCalculation, GenerateHistory

  def setup
    @regime = regimes(:pas)
    @header = transaction_headers(:pas_annual)

    @user = User.system_account
    Thread.current[:current_user] = @user

    @processor = Permits::PasCategoryProcessor.new(@header)
    build_mock_calculator
  end

  def test_fetch_unique_pas_permits_returns_list_of_permits
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    set_file_content(file_data)

    permits = @header.transaction_details.
      group(:reference_3, :customer_reference).count
    assert_equal permits, @processor.fetch_unique_pas_permits
  end

  def test_only_invoices_in_file_returns_true_when_only_invoices_in_file_for_permit
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    set_file_content(file_data)

    assert @processor.only_invoices_in_file?(reference_3: 'AAAA0001',
                                             customer_reference: 'A')
  end

  def test_only_invoices_in_file_returns_false_when_credits_in_file_for_permit
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    set_file_content(file_data)

    refute @processor.only_invoices_in_file?(reference_3: 'AAAA0002',
                                             customer_reference: 'B')
  end

  def test_find_historic_transactions_returns_empty_collection_when_no_matches_found
    @regime.transaction_details.historic.where(reference_3: 'AAAA0001',
                                               customer_reference: 'A').
                                               destroy_all

    assert @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A').empty?
  end

  def test_find_historic_transactions_returns_most_recent_transactions_if_possible
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    transactions = set_historic_content(historic_data)

    matches = @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A')
    assert_equal 1, matches.count
    assert_equal transactions.second, matches.first
  end

  def test_find_historic_transactions_returns_collection_matching_period_start
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    transactions = set_historic_content(historic_data)

    matches = @processor.find_historic_transactions(
      reference_3: 'AAAA0001', customer_reference: 'A')
    assert_equal 2, matches.count
    assert_equal transactions.first, matches.first
    assert_equal transactions.second, matches.second
  end

  def test_set_category_sets_category
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
    ]

    transaction = set_file_content(file_data).first

    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' }
    ]

    matched = set_historic_content(historic_data).first

    @processor.set_category(transaction, matched, :green, 'Level 99')
    assert_equal matched.category, transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Assigned matching category', sc.logic
    assert_equal 'Level 99', sc.suggestion_stage
    assert sc.green?
  end

  def test_set_category_sets_matched_transaction
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
    ]

    transaction = set_file_content(file_data).first

    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' }
    ]

    matched = set_historic_content(historic_data).first

    @processor.set_category(transaction, matched, :amber, 'Level')
    assert_equal matched.category, transaction.reload.category
    sc = transaction.suggested_category
    assert_equal matched, sc.matched_transaction, 'Matched transaction incorrect'
    assert_equal 'Assigned matching category', sc.logic
    assert sc.amber?, 'Confidence not AMBER'
  end

  def test_set_category_sets_charge_info
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
    ]
    transaction = set_file_content(file_data).first

    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' }
    ]
    matched = set_historic_content(historic_data).first

    @processor.set_category(transaction, matched, :green, 'Level')
    assert_not_nil transaction.charge_calculation, 'Charge calculation not set'
    assert_not_nil transaction.tcm_charge, 'Charge not extracted'
  end

  def test_set_category_does_not_set_category_when_category_removed
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
    ]
    transaction = set_file_content(file_data).first

    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' }
    ]
    matched = set_historic_content(historic_data).first

    p = PermitStorageService.new(@header.regime)
    p.update_or_create_new_version(matched.category, 'test', '1920', 'excluded')
    @processor.set_category(transaction, matched, :green, 'Level')
    assert_nil transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Category not valid for financial year', sc.logic
    assert sc.red?, "Confidence not RED"
  end

  def test_set_category_does_not_set_category_if_calculation_error
    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
    ]
    transaction = set_file_content(file_data).first

    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A',
        line_amount: 1234, period_start: '2-JUN-2019' }
    ]
    matched = set_historic_content(historic_data).first

    build_mock_calculator_with_error

    @processor.set_category(transaction, matched, :green, 'Level')
    assert_nil transaction.reload.category
    sc = transaction.suggested_category
    assert_equal 'Error assigning charge', sc.logic
    assert sc.red?, "Confidence not RED"
  end


# Annual Billing:
#   Single permit - Stage 1 ---------------------------------------
  #     Match 1 (green)
  def test_annual_single_stage_1_single_match_is_green
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.green?, 'Not GREEN')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Annual billing (single) - Stage 1', sc.suggestion_stage,
                'Wrong stage')
  end

#     Multiple matches (red)
  def test_annual_single_stage_1_multiple_matches_are_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category was set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('Multiple historic matches found', sc.logic, 'Wrong outcome')
    assert_equal('Annual billing (single) - Stage 1', sc.suggestion_stage,
                'Wrong stage')
  end

  #     No matches (red) - will never happen in Stage 1 as this will try
  #     again without :customer_reference and go into Stage 2
  #     when no matches found

#   Single permit - Stage 2 (ignores customer_reference) --------------
#     Match 1 (green)
  def test_annual_single_stage_2_single_match_is_green
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.green?, 'Not GREEN')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Annual billing (single) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
  end

#     Multiple matches (red)
  def test_annual_single_stage_1_multiple_matches_are_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category was set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('Multiple historic matches found', sc.logic, 'Wrong outcome')
    assert_equal('Annual billing (single) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
  end

#     No matches (red)
  def test_annual_single_stage_2_no_matches_are_red
    @regime.transaction_details.historic.where(reference_3: 'AAAA0001',
                                               customer_reference: 'A').
                                               destroy_all

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category was set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
    assert_equal('Annual billing (single) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
  end

#   Mutliple permits - Stage 1 ---------------------------------------
#     Match same number (amber)
  def test_annual_multiple_stage_1_all_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 9876 },
      { reference_3: 'AAAA0001', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    expected = ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Annual billing (multiple) - Stage 1', sc.suggestion_stage,
                'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#     Multiple matches (red)
  def test_annual_multiple_stage_1_all_do_not_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 9876 },
      { reference_3: 'AAAA0001', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('Number of matching transactions differs from number in file', sc.logic, 'Wrong outcome')
      assert_equal('Annual billing (multiple) - Stage 1', sc.suggestion_stage,
                'Wrong stage')
    end
  end

  #     No matches (red) - will never happen in Stage 1 as this will try
  #     again without :customer_reference and go into Stage 2
  #     when no matches found

#     No matches (red)


#   Multiple permits - Stage 2 (ignores customer_reference)
#     Match same number (amber)
  def test_annual_multiple_stage_2_all_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 9876 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    expected = ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Annual billing (multiple) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#     Multiple matches (red)
  def test_annual_multiple_stage_2_all_do_not_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 9876 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('Number of matching transactions differs from number in file', sc.logic, 'Wrong outcome')
      assert_equal('Annual billing (multiple) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
    end
  end

#     No matches (red)
  def test_annual_multiple_stage_2_none_match_is_red
    historic_data = [
      { reference_3: 'AAAA0002', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0002', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2019' },
      { reference_3: 'AAAA0002', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0002', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0002', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'C', line_amount: 9876 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
      assert_equal('Annual billing (multiple) - Stage 2', sc.suggestion_stage,
                'Wrong stage')
    end
  end


# Supplementary Billing:
#   Debits:
#     Single debit - Stage 1/2 ---------------------------------------
#       Match 1 (green)
  def test_supplemental_single_stage_1_single_match_is_green
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.green?, 'Not GREEN')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 1',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Multiple matches (only one most recent period start) (amber)
  def test_supplemental_single_stage_2_multiple_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.amber?, 'Not AMBER')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 2',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Mutliple matches (no single recent) (red)
  def test_supplemental_single_stage_2_multiple_no_single_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('Multiple historic matches found', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 2',
                 sc.suggestion_stage, 'Wrong stage')
  end

#     Single debit - Stage 3/4 (ignores customer reference) -----------
#       Match 1 (green)
  def test_supplemental_single_stage_3_single_match_is_green
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.green?, 'Not GREEN')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 3',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Multiple matches (only one most recent period start) (amber)
  def test_supplemental_single_stage_3_multiple_single_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.amber?, 'Not AMBER')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 4',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Mutliple matches (no single recent) (red)
  def test_supplemental_single_stage_4_multiple_no_single_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('Multiple historic matches found', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 4',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       No matches (red)
  def test_supplemental_single_stage_3_multiple_no_matches_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '2-JUN-2020',
        period_end: '1-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-JAN-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary invoice (single) - Stage 3',
                 sc.suggestion_stage, 'Wrong stage')
  end

#     Multiple debits - Stage 1 ---------------------------------------
#       Match all (amber)
  def test_supplemental_multiple_stage_1_all_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 1',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#     Mutliple debits - Stage 2 ---------------------------------------
#       Match all when using most recent period start (amber)
  def test_supplemental_multiple_stage_2_period_start_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 2',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#       Doesnt match all when using most recent period start (red)
  def test_supplemental_multiple_stage_2_no_period_start_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUL-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('Number of matching transactions differs from number in file', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 2',
                   sc.suggestion_stage, 'Wrong stage')
    end
  end

#     Multiple debits - Stage 3 (ignores customer reference)
#       Match all (amber)
  def test_supplemental_multiple_stage_3_all_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 3',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#       No matches (red)
  def test_supplemental_multiple_stage_3_no_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '1-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '3-JAN-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 3',
                   sc.suggestion_stage, 'Wrong stage')
    end
  end

#     Multiple debits - Stage 4 (ignores customer reference) ----------
#       Match all when using most recent period start (amber)
  def test_supplemental_multiple_stage_4_period_start_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 4',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#       Doesnt match all when using most recent period start (red)
  def test_supplemental_multiple_stage_4_no_period_start_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUL-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'C', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('Number of matching transactions differs from number in file', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary invoice (multiple) - Stage 4',
                   sc.suggestion_stage, 'Wrong stage')
    end
  end

#   Credits:
#     Single credit - Stage 1/2 ---------------------------------------
#       Match 1 (green)
  def test_supplemental_credit_single_stage_1_single_match_is_green
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.green?, 'Not GREEN')
    assert(sc.admin_lock?, 'Not locked')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary credit (single) - Stage 1',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Multiple matches (only one most recent period start) (amber)
  def test_supplemental_credit_single_stage_2_multiple_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_equal('2.4.6', t.reload.category, 'Incorrect category set')
    sc = t.suggested_category
    assert(sc.amber?, 'Not AMBER')
    assert(sc.admin_lock?, 'Not locked')
    assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary credit (single) - Stage 2',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       Mutliple matches (no single recent) (red)
  def test_supplemental_credit_single_stage_2_multiple_no_single_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    refute(sc.admin_lock?, 'Is locked')
    assert_equal('Multiple historic matches found', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary credit (single) - Stage 2',
                 sc.suggestion_stage, 'Wrong stage')
  end

#       No matches (red)
  def test_supplemental_credit_single_stage_1_no_matches_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '2-JUN-2020',
        period_end: '1-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-JAN-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1234 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    t = set_file_content(file_data).first

    @processor.suggest_categories

    assert_nil(t.reload.category, 'Category set')
    sc = t.suggested_category
    assert(sc.red?, 'Not RED')
    refute(sc.admin_lock?, 'Is locked')
    assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
    assert_equal('Supplementary credit (single) - Stage 1',
                 sc.suggestion_stage, 'Wrong stage')
  end


#     Multiple credits - Stage 1 ---------------------------------------
#       Match all (amber)
  def test_supplemental_credit_multiple_stage_1_all_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 1345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert(sc.admin_lock?, 'Not locked')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary credit (multiple) - Stage 1',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#       No matches (red)
  def test_supplemental_credit_multiple_stage_1_no_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2019',
        period_end: '1-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.6',
        line_amount: 2345, period_start: '2-JUN-2020',
        period_end: '3-JAN-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.5',
        line_amount: 3456, period_start: '1-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      refute(sc.admin_lock?, 'Is locked')
      assert_equal('No previous bill found', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary credit (multiple) - Stage 1',
                   sc.suggestion_stage, 'Wrong stage')
    end
  end

#     Mutliple credits - Stage 2 ---------------------------------------
#       Match all when using most recent period start (amber)
  def test_supplemental_credit_multiple_stage_2_period_start_match_is_amber
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories
    expected =  ['2.4.5', '2.4.6']
    assigned = []

    file[0..1].each do |t|
      assert_not_nil(t.reload.category, 'No category set')
      assigned << t.category
      sc = t.suggested_category
      assert(sc.amber?, 'Not AMBER')
      assert(sc.admin_lock?, 'Not locked')
      assert_equal('Assigned matching category', sc.logic, 'Wrong outcome')
      assert_equal('Supplementary credit (multiple) - Stage 2',
                   sc.suggestion_stage, 'Wrong stage')
    end
    assert_equal(expected, assigned.sort, 'Categories not assigned correctly')
  end

#       Doesnt match all when using most recent period start (red)
  def test_supplemental_credit_multiple_stage_2_no_period_start_match_is_red
    historic_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.5',
        line_amount: 1234, period_start: '1-JUN-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.6',
        line_amount: 2345, period_start: '1-JUL-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: 3456, period_start: '1-APR-2020',
        period_end: '31-MAR-2021' },
      { reference_3: 'AAAA0001', customer_reference: 'B', category: '2.4.4',
        line_amount: 4567, period_start: '24-APR-2019' },
      { reference_3: 'AAAA0001', customer_reference: 'A', category: '2.4.4',
        line_amount: -2234, period_start: '3-JUN-2019' }
    ]

    set_historic_content(historic_data)

    file_data = [
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -234 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: -345 },
      { reference_3: 'AAAA0001', customer_reference: 'A', line_amount: 2345 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: 3456 },
      { reference_3: 'AAAA0002', customer_reference: 'B', line_amount: -2234 }
    ]

    file = set_file_content(file_data)

    @processor.suggest_categories

    file[0..1].each do |t|
      assert_nil(t.reload.category, 'Category set')
      sc = t.suggested_category
      assert(sc.red?, 'Not RED')
      assert_equal('Number of matching transactions differs from number in file', sc.logic, 'Wrong outcome')
      refute(sc.admin_lock?, 'Is locked')
      assert_equal('Supplementary credit (multiple) - Stage 2',
                   sc.suggestion_stage, 'Wrong stage')
    end
  end


  def set_file_content(content)
    results = []
    t = transaction_details(:pas_annual)

    content.each_with_index do |attrs, i|
      tt = t.dup
      tt.status = 'unbilled'
      tt.sequence_number = 2 + i
      tt.line_amount = 1234
      tt.customer_reference = 'A'
      tt.transaction_header_id = @header.id
      tt.period_start = '1-APR-2020'
      tt.period_end = '31-MAR-2021'
      tt.tcm_financial_year = '2021'
      tt.category = nil
      tt.save!
      tt.update(attrs)
      results << tt
    end
    results
  end

  def set_historic_content(content)
    f = transaction_files(:pas_sroc_file)
    t = transaction_details(:pas)
    history = []

    content.each_with_index do |attrs, i|
      t2 = t.dup
      t2.reference_1 = '0123456'
      t2.reference_2 = 'AAA/A0011'
      t2.reference_3 = 'AAAA0001'
      t2.transaction_reference = 'E12344'
      t2.customer_reference = 'A'
      t2.status = 'billed'
      t2.line_amount = 12567
      t2.category = '2.4.5'
      t2.period_start = '1-APR-2018'
      t2.period_end = '31-MAR-2019'
      t2.tcm_financial_year = '1819'
      t2.transaction_file_id = f.id
      t2.save!
      t2.update(attrs)
      history << t2
    end
    history
  end
end
