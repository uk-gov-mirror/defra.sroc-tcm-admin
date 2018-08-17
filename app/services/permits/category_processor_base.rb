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
      header.transaction_details.unbilled.distinct.order(reference_1: :asc).
        pluck(:reference_1)
    end

    def set_category(transaction, category, confidence_level)
      fy = transaction.tcm_financial_year
      # need to ensure the found category is still valid
      cat = permit_store.code_for_financial_year(category, fy)
      if cat.nil?
        transaction.category_logic = 'Category not valid for financial year'
      else
        transaction.category = category
        transaction.charge_calculation = calc_charge(transaction)
        if transaction.charge_calculation_error?
          transaction.category = nil
          transaction.tcm_charge = nil
          transaction.category_logic = 'Error assigning charge'
        else
          transaction.tcm_charge = TransactionCharge.extract_correct_charge(transaction)
          transaction.category_logic = 'Assigned matching category'
          transaction.category_confidence_level = confidence_level
        end
      end
      transaction.save!
    end

    def calc_charge(transaction)
      TransactionCharge.invoke_charge_calculation(calculator,
                                                  presenter.new(transaction))
    end

    def not_annual_bill(where_args)
      # record that this file contains credits for this consent
      # so it is not an annual bill
      set_logic_message(where_args, 'Not part of an annual bill')
    end

    def no_historic_transaction(where_args)
      # record that we couldn't find a previous bill
      set_logic_message(where_args, 'No previous bill found')
    end

    def set_logic_message(where_args, msg)
      header.transaction_details.unbilled.where(where_args).each do |t|
        t.update_attributes(category_logic: msg)
      end
    end

    def only_invoices_in_file?(where_args)
      header.transaction_details.unbilled.where(where_args).
        credits.count.zero?
    end

    def permit_store
      @permit_store ||= PermitStorageService.new(regime, user)
    end

    def calculator
      @calculator ||= CalculationService.new(user)
    end
  end
end
