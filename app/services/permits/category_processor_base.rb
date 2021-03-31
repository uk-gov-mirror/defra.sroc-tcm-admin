# frozen_string_literal: true

module Permits
  class CategoryProcessorBase
    include RegimePresenter
    attr_reader :user, :header, :regime

    def initialize(file_header, user = nil)
      # when instantiated from a controller the 'current_user' should
      # be passed in. This will allow us to audit actions etc.
      @header = file_header
      @regime = file_header.regime
      @user = user
    end

    def fetch_unique_consents
      header.transaction_details.unbilled.distinct.order(reference_1: :asc).pluck(:reference_1)
    end

    def set_category(transaction, matched_transaction, confidence_level,
                     stage, admin_lock: false)

      fy = transaction.tcm_financial_year
      # need to ensure the found category is still valid
      category = matched_transaction.category
      sc = suggested_category_for(transaction)

      sc.category = category
      sc.suggestion_stage = stage
      sc.matched_transaction = matched_transaction

      cat = permit_store.code_for_financial_year(category, fy)
      if cat.nil?
        sc.logic = "Category not valid for financial year"
        sc.confidence_level = :red
      else
        transaction.category = category
        transaction.charge_calculation = calc_charge(transaction)
        if transaction.charge_calculation_error?
          transaction.category = nil
          transaction.tcm_charge = nil
          sc.logic = "Error assigning charge"
          sc.confidence_level = :red
        else
          transaction.tcm_charge = TransactionCharge.extract_correct_charge(transaction)
          sc.logic = "Assigned matching category"
          sc.confidence_level = confidence_level
          sc.admin_lock = admin_lock
        end
      end
      TransactionDetail.transaction do
        sc.save!
        transaction.save!
      end
    end

    def calc_charge(transaction)
      CalculateCharge.call(transaction: transaction).charge_calculation
    end

    def not_annual_bill(where_args, stage)
      # record that this file contains credits for this consent
      # so it is not an annual bill
      make_suggestion(where_args, :red, "Not part of an annual bill", stage)
    end

    def make_suggestion(args, confidence, logic, stage)
      unbilled_transactions(args) do |t|
        sc = suggested_category_for(t)
        sc.logic = logic
        sc.confidence_level = confidence
        sc.suggestion_stage = stage
        sc.save!
      end
    end

    def no_historic_transaction(where_args, stage)
      # record that we couldn't find a previous bill
      make_suggestion(where_args, :red, "No previous bill found", stage)
    end

    def multiple_historic_matches(where_args, stage)
      make_suggestion(where_args, :red,
                      "Multiple historic matches found", stage)
    end

    def multiple_matching_transactions(where_args, stage)
      make_suggestion(where_args, :red,
                      "Multiple matching transactions found in file", stage)
    end

    def different_number_of_matching_transactions(where_args, stage)
      make_suggestion(where_args, :red,
                      "Number of matching transactions differs from number in file", stage)
    end

    def set_logic_message(where_args, msg)
      unbilled_transactions(where_args) do |t|
        # FIXME: not using this now - only left until all
        # supplementarty stuff done
        sc = suggested_category_for(t)
        sc.logic = msg
        sc.suggestion_stage = "Unknown"
        sc.confidence_level = :red
        sc.save!
      end
    end

    def only_invoices_in_file?(where_args)
      header.transaction_details.unbilled.where(where_args).credits.count.zero?
    end

    def unbilled_transactions(where_args)
      header.transaction_details.unbilled.where(where_args).each do |t|
        yield t if block_given?
      end
    end

    def more_than_one_invoice_in_file_for_permit?(permit_args)
      header.transaction_details.invoices.where(permit_args).count > 1
    end

    def more_than_one_credit_in_file_for_permit?(permit_args)
      header.transaction_details.credits.where(permit_args).count > 1
    end

    def suggested_category_for(transaction)
      transaction.suggested_category || transaction.build_suggested_category
    end

    def permit_store
      @permit_store ||= PermitStorageService.new(regime, user)
    end
  end
end
