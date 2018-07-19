# frozen_string_literal: true

class PermitCategoryProcessor
  include RegimePresenter
  attr_reader :user, :header, :regime

  def initialize(file_header, user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc.
    @header = file_header
    @regime = file_header.regime
    @user = user
  end

  def suggest_categories
    consents = fetch_unique_consents

    consents.each do |consent|
      if only_invoices_in_file?(consent)
        last_historic_transaction = find_historic_transaction(consent)
        if last_historic_transaction
          category = last_historic_transaction.category
          each_transaction_for(consent) do |transaction|
            set_category(transaction, category)
          end
        else
          no_historic_transaction(consent)
        end
      else
        not_annual_bill(consent)
      end
    end
  end

  def each_transaction_for(consent)
    header.transaction_details.where(reference_1: consent).each do |t|
      yield t if block_given?
    end
  end

  def set_category(transaction, category)
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
        transaction.category_logic = 'Error assigning charge'
      else
        transaction.category_logic = 'Assigned matching category'
      end
    end
    transaction.save!
  end

  def calc_charge(transaction)
    TransactionCharge.invoke_charge_calculation(calculator,
                                                presenter.new(transaction))
  end

  def no_historic_transaction(consent)
    # record that we couldn't find a previous bill
    set_logic_message(consent, 'No previous bill found')
  end

  def not_annual_bill(consent)
    # record that this file contains credits for this consent
    # so it is not an annual bill
    set_logic_message(consent, 'Not part of an annual bill')
  end

  def set_logic_message(consent, msg)
    # Don't use update_all as it won't trigger callbacks so no auditing
    header.transaction_details.where(reference_1: consent).each do |t|
      t.update_attributes(category_logic: msg)
    end
  end

  def fetch_unique_consents
    header.transaction_details.distinct.order(reference_1: :asc).
      pluck(:reference_1)
  end

  def find_historic_transaction(consent)
    regime.transaction_details.historic.where(reference_1: consent).
      order(period_end: :desc).first
  end

  def only_invoices_in_file?(consent)
    header.transaction_details.where(reference_1: consent).
      credits.count.zero?
  end

  def permit_store
    @permit_store ||= PermitStorageService.new(regime, user)
  end

  def calculator
    @calculator ||= CalculationService.new(user)
  end
end
