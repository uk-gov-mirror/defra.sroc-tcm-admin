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
            handle_multiple_annual_permits(permit_args, count)
          end
        else
          handle_supplementary_billing(permit_args)
        end
      end
    end

    ### Annual Billing ===============================
    #
    def handle_single_annual_permit(permit_args)
      stage = 'Annual billing (single) - Stage 1'
      transaction = header.transaction_details.find_by(permit_args)
      historic_transactions = find_historic_transactions(permit_args)

      if historic_transactions.count.zero?
        # try without customer ref
        stage = 'Annual billing (single) - Stage 2'
        historic_transactions = find_historic_transactions(
          permit_args.except(:customer_reference))
      end

      if historic_transactions.count == 1
        set_category(transaction, historic_transactions.first,
                     :green, stage)
      elsif historic_transactions.count > 1
        multiple_historic_matches({ id: transaction.id }, stage)
      else
        no_historic_transaction(permit_args, stage)
      end
    end

    def handle_multiple_annual_permits(permit_args, num_records)
      stage = 'Annual billing (multiple) - Stage 1'
      historic_transactions = find_historic_transactions(permit_args)

      if historic_transactions.count.zero?
        # try without customer ref
        stage = 'Annual billing (multiple) - Stage 2'
        historic_transactions = find_historic_transactions(
          permit_args.except(:customer_reference))
      end

      if historic_transactions.count == num_records
        count = 0
        header.transaction_details.where(permit_args).each do |t|
          set_category(t, historic_transactions[count], :amber, stage)
          count += 1
        end
      elsif historic_transactions.count.zero?
        no_historic_transaction(permit_args, stage)
      else
        different_number_of_matching_transactions(permit_args, stage)
      end
    end

    ### Supplementary Billing ===============================
    #
    def handle_supplementary_billing(permit_args)
      debits = header.transaction_details.invoices.where(permit_args).
        group(:reference_3, :customer_reference, :period_end).count
      debits.each do |args, count|
        handle_supplementary_debits(group_to_args(args), count)
      end

      credits = header.transaction_details.credits.where(permit_args).
        group(:reference_3, :customer_reference, :period_end).count

      credits.each do |args, count|
        handle_supplementary_credits(group_to_args(args), count)
      end
    end

    ### Supplementary Debits ===============================
    #
    def handle_supplementary_debits(query_args, count)
      if count > 1
        handle_multiple_supplementary_debits(query_args, count)
      else
        stage = "Supplementary invoice (single) - Stage 1"
        transaction = header.transaction_details.invoices.find_by(query_args)
        with_customer_reference = true
        invoices = find_historic_debits(query_args)

        if invoices.count.zero?
          invoices = find_historic_debits(
            query_args.except(:customer_reference))
          stage = "Supplementary invoice (single) - Stage 3"
          with_customer_reference = false
        end

        if invoices.count.zero?
          no_historic_transaction({ id: transaction.id }, stage)
        elsif invoices.count == 1
          set_category(transaction, invoices.first, :green, stage)
        else
          stage = if with_customer_reference
            "Supplementary invoice (single) - Stage 2"
          else
            "Supplementary invoice (single) - Stage 4"
          end

          if invoices.first.period_start != invoices.second.period_start
            set_category(transaction, invoices.first, :amber, stage)
          else
            multiple_historic_matches({ id: transaction.id }, stage)
          end
        end
      end
    end

    def handle_multiple_supplementary_debits(query_args, count)
      # multiple invoices in file
      stage = "Supplementary invoice (multiple) - Stage 1"
      invoices = find_historic_debits(query_args)
      with_customer_reference = true

      if invoices.count.zero?
        invoices = find_historic_debits(
          query_args.except(:customer_reference))
        stage = "Supplementary invoice (multiple) - Stage 3"
        with_customer_reference = false
      end

      if invoices.count.zero?
        header.transaction_details.invoices.where(query_args).each do |t|
          no_historic_transaction({ id: t.id }, stage)
        end
      elsif invoices.count == count
        cnt = 0
        header.transaction_details.invoices.where(query_args).each do |t|
          set_category(t, invoices[cnt], :amber, stage)
          cnt += 1
        end
      else
        if with_customer_reference
          stage = "Supplementary invoice (multiple) - Stage 2"
          q = query_args
        else
          stage = "Supplementary invoice (multiple) - Stage 4"
          q = query_args.except(:customer_reference)
        end

        invoices = find_historic_debits(
          q.merge({ period_start: invoices.first.period_start }))

        if invoices.count == count
          cnt = 0
          header.transaction_details.invoices.where(query_args).each do |t|
            set_category(t, invoices[cnt], :amber, stage)
            cnt += 1
          end
        else
          header.transaction_details.invoices.where(query_args).each do |t|
            different_number_of_matching_transactions({ id: t.id }, stage)
          end
        end
      end
    end

    ### Supplementary Credits ===============================
    #
    def handle_supplementary_credits(query_args, count)
      stage = "Supplementary credit (single) - Stage 1"

      if count > 1
        handle_multiple_supplementary_credits(query_args, count)
      else
        transaction = header.transaction_details.credits.find_by(query_args)
        invoices = find_historic_debits(query_args)

        if invoices.count.zero?
          no_historic_transaction({ id: transaction.id }, stage)
        elsif invoices.count == 1
          set_category(transaction, invoices.first, :green, stage, true)
        else
          stage = "Supplementary credit (single) - Stage 2"

          if invoices.first.period_start != invoices.second.period_start
            set_category(transaction, invoices.first, :amber, stage, true)
          else
            multiple_historic_matches({ id: transaction.id }, stage)
          end
        end
      end
    end

    def handle_multiple_supplementary_credits(query_args, count)
      # multiple credits in file
      stage = "Supplementary credit (multiple) - Stage 1"
      invoices = find_historic_debits(query_args)

      if invoices.count.zero?
        header.transaction_details.credits.where(query_args).each do |t|
          no_historic_transaction({ id: t.id }, stage)
        end
      elsif invoices.count == count
        cnt = 0
        header.transaction_details.credits.where(query_args).each do |t|
          set_category(t, invoices[cnt], :amber, stage, true)
          cnt += 1
        end
      else
        stage = "Supplementary credit (multiple) - Stage 2"
        invoices = find_historic_debits(
          query_args.merge({ period_start: invoices.first.period_start }))

        if invoices.count == count
          cnt = 0
          header.transaction_details.credits.where(query_args).each do |t|
            set_category(t, invoices[cnt], :amber, stage, true)
            cnt += 1
          end
        else
          header.transaction_details.credits.where(query_args).each do |t|
            different_number_of_matching_transactions({ id: t.id }, stage)
          end
        end
      end
    end

    def fetch_unique_pas_permits
      # group transactions by absolute original permit reference (:reference_3)
      # and customer reference
      header.transaction_details.group(:reference_3, :customer_reference).count
    end

    def find_historic_debits(args)
      regime.transaction_details.historic.invoices.where(args).
        order(period_start: :desc)
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

    def group_to_args(group)
      {
        reference_3: group[0],
        customer_reference: group[1],
        period_end: group[2]
      }
    end
  end
end
