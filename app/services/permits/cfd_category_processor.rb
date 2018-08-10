# frozen_string_literal: true
module Permits
  class CfdCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      consents = fetch_unique_consents

      consents.each do |consent|
        consent_args = consent_to_args(consent)
        if only_invoices_in_file?(consent_args)
          last_historic_transaction = find_latest_historic_transaction(consent_args)
          if last_historic_transaction
            category = last_historic_transaction.category
            header.transaction_details.unbilled.where(consent_args).each do |t|
              set_category(t, category)
            end
          else
            no_historic_transaction(consent_args)
          end
        else
          not_annual_bill(consent_args)
        end
      end
    end

    def find_latest_historic_transaction(consent_args)
      regime.transaction_details.historic.invoices.where(consent_args).
        order(period_end: :desc).first
    end

    def consent_to_args(consent)
      { reference_1: consent }
    end
  end
end
