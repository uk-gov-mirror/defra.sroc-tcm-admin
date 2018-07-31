# frozen_string_literal: true

module Permits
  class WmlCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      permits = fetch_unique_consents

      permits.each do |permit|
        if only_invoices_in_file?(permit)
          grouped_permits = find_unique_permits(permit)

          grouped_permits.keys.each do |k|
            historic_transaction = find_latest_historic_transaction(k)
            if historic_transaction
              transactions = get_transaction_group(k)
              transactions.each do |transaction|
                set_category(transaction, historic_transaction.category)
              end
            else
              no_historic_transaction(k)
            end
          end
        else
          not_annual_bill(permit)
        end
      end
    end

    def no_historic_transaction(key)
      # record that we couldn't find a previous bill
      set_logic_message({ reference_1: key[0], reference_3: key[1] },
                        'No previous bill found')
    end

    def find_unique_permits(permit)
      # use charge code (reference_3) to further differentiate
      header.transaction_details.unbilled.where(reference_1: permit).
        group(:reference_1, :reference_3).count
    end

    def get_transaction_group(key)
      header.transaction_details.unbilled.where(reference_1: key[0],
                                                reference_3: key[1])
    end

    def find_latest_historic_transaction(key)
      regime.transaction_details.historic.invoices.
        where(reference_1: key[0], reference_3: key[1]).
        order(transaction_reference: :desc).first
    end
  end
end
