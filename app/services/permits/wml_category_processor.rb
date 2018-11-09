# frozen_string_literal: true

module Permits
  class WmlCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      permits = fetch_unique_consents

      permits.each do |permit|
        if only_invoices_in_file?(reference_1: permit)
          handle_annual_billing(permit)
        else
          handle_supplementary_billing(permit)
        end
      end
    end

    def handle_annual_billing(permit)
      grouped_permits = find_unique_permits(permit)

      grouped_permits.keys.each do |k|
        permit_args = keys_to_args(k)
        historic_transaction = find_latest_historic_transaction(permit_args)
        if historic_transaction
          unbilled_transactions(permit_args) do |t|
            set_category(t, historic_transaction, :green, 'Annual billing')
          end
        else
          no_historic_transaction(permit_args, 'Annual billing')
        end
      end
    end

    def handle_supplementary_billing(permit)
      header.transaction_details.unbilled.where(reference_1: permit).each do |t|
        if t.invoice?
          handle_supplementary_invoice(t)
        else
          handle_supplementary_credit(t)
        end
      end
    end

    def handle_supplementary_invoice(transaction)
      stage = "Supplementary invoice stage 1"
      # are there more than one of this permit reference in the file?
      if more_than_one_invoice_in_file_for_permit?(reference_1: transaction.reference_1)
        multiple_activities(transaction, stage)
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
      # are there more than one of this permit reference in the file?
      if more_than_one_credit_in_file_for_permit?(reference_1: transaction.reference_1)
        multiple_activities(transaction, stage)
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

    def find_unique_permits(permit)
      # use charge code (reference_3) to further differentiate
      header.transaction_details.unbilled.where(reference_1: permit).
        group(:reference_1, :reference_3).count
    end

    def find_latest_historic_transaction(where_args)
      regime.transaction_details.historic.invoices.where(where_args).
        order(transaction_reference: :desc).first
    end

    def find_historic_invoices(transaction)
      regime.transaction_details.historic.invoices.
        where(reference_1: transaction.reference_1).
        where(period_end: transaction.period_end).
        order(period_start: :desc)
    end

    def multiple_activities(transaction, stage)
      make_suggestion({ id: transaction.id }, :red,
                      "Multiple activities for permit",
                      stage)
    end

    def keys_to_args(keys)
      {
        reference_1: keys[0],
        reference_3: keys[1]
      }
    end
  end
end
