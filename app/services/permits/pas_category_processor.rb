# frozen_string_literal: true

module Permits
  class PasCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      permits = fetch_unique_pas_permits

      permits.each do |keys, count|
        permit_args = keys_to_args(keys)
        if only_invoices_in_file?(permit_args)
          if count == 1
            historic_transactions = find_historic_transactions(permit_args)
            if historic_transactions.count == 1
              transaction = header.transaction_details.find_by(permit_args)
              category = historic_transactions.first.category
              set_category(transaction, category)
            elsif historic_transactions.count > 1
              # handle multiple matching for same start period
              multiple_historic_matches(permit_args)
            else
              no_historic_transaction(permit_args)
            end
          else
            # multiple transactions in file for permit
            multiple_matching_permits(permit_args)
          end
        else
          not_annual_bill(permit_args)
        end
      end
    end

    def fetch_unique_pas_permits
      # group transactions by absolute original permit reference (:reference_3)
      # and customer reference
      header.transaction_details.group(:reference_3, :customer_reference).count
    end

    def multiple_historic_matches(permit_args)
      set_logic_message(permit_args, 'Multiple historic matches found')
    end

    def multiple_matching_permits(permit_args)
      set_logic_message(permit_args, 'Multiple matching permits in file found')
    end

    def find_historic_transactions(args)
      q = regime.transaction_details.historic.invoices.where(args)
      most_recent = q.order(period_start: :desc).first
      if most_recent
        q.where(period_start: most_recent.period_start)
      else
        q
      end
    end

    def keys_to_args(keys)
      {
        reference_3: keys[0],
        customer_reference: keys[1]
      }
    end
  end
end
