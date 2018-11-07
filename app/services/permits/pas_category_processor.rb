# frozen_string_literal: true

module Permits
  class PasCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      permits = fetch_unique_pas_permits

      permits.each do |keys, count|
        permit_args = keys_to_args(keys)
        if only_invoices_in_file?(permit_args)
          if count == 1
            handle_single_annual_permit(permit_args)
          else
            multiple_matching_transactions(permit_args, "Annual billing")
          end
        else
          handle_supplementary_billing(permit_args)
        end
      end
    end

    def handle_single_annual_permit(permit_args)
      historic_transactions = find_historic_transactions(permit_args)
      if historic_transactions.count == 1
        transaction = header.transaction_details.find_by(permit_args)
        set_category(transaction, historic_transactions.first,
                     :green, 'Annual billing')
      elsif historic_transactions.count > 1
        # handle multiple matching for same start period
        multiple_historic_matches(permit_args, 'Annual billing')
      else
        no_historic_transaction(permit_args, 'Annual billing')
      end
    end

    def handle_supplementary_billing(permit_args)
      header.transaction_details.unbilled.where(permit_args).each do |t|
        if t.invoice?
          handle_supplementary_invoice(t)
        else
          handle_supplementary_credit(t)
        end
      end
    end

    def handle_supplementary_invoice(transaction)
      stage = "Supplementary invoice stage 1"
      permit_args = args_from_transaction(transaction)

      if more_than_one_invoice_in_file_for_permit?(permit_args)
        multiple_matching_transactions({ id: transaction.id }, stage)
      else
        invoices = find_historic_invoices(transaction)
        if invoices.count.zero?
          no_historic_transaction({ id: transaction.id }, stage)
        elsif invoices.count == 1
          set_category(transaction, invoices.first, :amber, stage)
        else
          stage = "Supplementary invoice stage 2"
          if invoices.first.period_start != invoices.second.period_start
            set_category(transaction, invoices.first, :amber, stage)
          else
            no_historic_transaction({ id: transaction.id }, stage)
          end
        end
      end
    end

    def handle_supplementary_credit(transaction)
      stage = "Supplementary credit stage 1"
      permit_args = args_from_transaction(transaction)

      if more_than_one_credit_in_file_for_permit?(permit_args)
        multiple_matching_transactions({ id: transaction.id }, stage)
      else
        invoices = find_historic_invoices(transaction)
        if invoices.count.zero?
          no_historic_transaction({ id: transaction.id }, stage)
        elsif invoices.count == 1
          set_category(transaction, invoices.first, :green, stage, true)
        else
          stage = "Supplementary credit stage 2"
          if invoices.first.period_start != invoices.second.period_start
            set_category(transaction, invoices.first, :green, stage, true)
          else
            no_historic_transaction({ id: transaction.id }, stage)
          end
        end
      end
    end

    def fetch_unique_pas_permits
      # group transactions by absolute original permit reference (:reference_3)
      # and customer reference
      header.transaction_details.group(:reference_3, :customer_reference).count
    end

    def find_historic_invoices(transaction)
      regime.transaction_details.historic.invoices.
        where(reference_3: transaction.reference_3).
        where(customer_reference: transaction.customer_reference).
        where(period_end: transaction.period_end).
        order(period_start: :desc)
    end

    def multiple_historic_matches(permit_args, stage)
      make_suggestion(permit_args, :red,
                      'Multiple historic matches found', stage)
      # set_logic_message(permit_args, 'Multiple historic matches found')
    end

    def multiple_matching_transactions(permit_args, stage)
      make_suggestion(permit_args, :red,
                      "Multiple matching transactions found in file", stage)
      # unbilled_transactions(permit_args) do |t|
      #   sc = suggested_category_for(t)
      #   sc.logic = 'Multiple matching transactions found in file'
      #   sc.confidence_level = :red
      #   sc.suggestion_stage = stage
      #   sc.save!
      # end
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

    def args_from_transaction(t)
      keys_to_args([t.reference_3, t.customer_reference])
    end

    def keys_to_args(keys)
      {
        reference_3: keys[0],
        customer_reference: keys[1]
      }
    end
  end
end
