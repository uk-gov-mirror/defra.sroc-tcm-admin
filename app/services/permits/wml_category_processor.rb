# frozen_string_literal: true

module Permits
  class WmlCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      permits = fetch_unique_consents

      permits.each do |permit|
        if only_invoices_in_file?(reference_1: permit)
          grouped_permits = find_unique_permits(permit)

          grouped_permits.keys.each do |k|
            permit_args = keys_to_args(k)
            historic_transaction = find_latest_historic_transaction(permit_args)
            if historic_transaction
              header.transaction_details.unbilled.where(permit_args).each do |t|
                set_category(t, historic_transaction.category, :green)
              end
            else
              no_historic_transaction(permit_args)
            end
          end
        else
          not_annual_bill(reference_1: permit)
        end
      end
    end

    def find_unique_permits(permit)
      # use charge code (reference_3) to further differentiate
      header.transaction_details.unbilled.where(reference_1: permit).
        group(:reference_1, :reference_3).count
    end

    def find_latest_historic_transaction(where_args)
      regime.transaction_details.historic.invoices.where(where_args).
        order(transaction_reference: :desc).first
    end

    def keys_to_args(keys)
      {
        reference_1: keys[0],
        reference_3: keys[1]
      }
    end
  end
end
