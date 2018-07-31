# frozen_string_literal: true
module Permits
  class CfdCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      consents = fetch_unique_consents

      consents.each do |consent|
        if only_invoices_in_file?(consent)
          last_historic_transaction = find_latest_historic_transaction(consent)
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
      header.transaction_details.unbilled.where(reference_1: consent).each do |t|
        yield t if block_given?
      end
    end

    def no_historic_transaction(consent)
      # record that we couldn't find a previous bill
      set_logic_message({ reference_1: consent }, 'No previous bill found')
    end

    def find_latest_historic_transaction(consent)
      regime.transaction_details.historic.invoices.where(reference_1: consent).
        order(period_end: :desc).first
    end
  end
end
