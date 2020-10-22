# frozen_string_literal: true

module Permits
  class CfdCategoryProcessor < CategoryProcessorBase
    def suggest_categories
      consents = fetch_unique_consents

      consents.each do |consent|
        consent_args = consent_to_args(consent)
        if only_invoices_in_file?(consent_args)
          handle_annual_billing(consent_args)
        else
          handle_supplementary_billing(consent_args)
        end
      end
    end

    # overridden for CFD
    def only_invoices_in_file?(consent_args)
      like_clause = make_permit_discharge_matcher(consent_args[:reference_1])
      at = TransactionDetail.arel_table
      header.transaction_details.unbilled.where(at[:reference_1].matches(like_clause)).credits.count.zero?
    end

    def handle_annual_billing(consent_args)
      stage = "Annual billing - stage 1"
      last_invoice = find_latest_historic_invoice(consent_args)
      if last_invoice
        header.transaction_details.unbilled.where(consent_args).each do |t|
          set_category(t, last_invoice, :green, stage)
        end
      else
        stage = "Annual billing - stage 2"
        header.transaction_details.unbilled.where(consent_args).each do |t|
          # debugger
          last_invoice = find_latest_historic_invoice_version_for_annual(t)
          if last_invoice
            set_category(t, last_invoice, :green, stage)
          else
            no_historic_transaction({ id: t.id }, stage)
          end
        end
      end
    end

    def handle_supplementary_billing(consent_args)
      header.transaction_details.unbilled.where(consent_args).each do |t|
        if t.invoice?
          handle_supplementary_invoice(t, consent_args)
        else
          handle_supplementary_credit(t, consent_args)
        end
      end
    end

    def handle_supplementary_invoice(transaction, consent_args)
      history_args = consent_args.merge(period_start: transaction.period_start)
      last_invoice = find_latest_historic_invoice(history_args)
      if last_invoice
        set_category(transaction, last_invoice, :green, "Supplementary invoice stage 1")
      else
        invoice = find_latest_historic_invoice_version(transaction)

        if invoice
          set_category(transaction, invoice, :amber, "Supplementary invoice stage 2")
        else
          # possibly multiple transactions we're working through for this
          # consent so identify transaction explicitly
          no_historic_transaction({ id: transaction.id }, "Supplementary invoice")
        end
      end
    end

    def handle_supplementary_credit(transaction, _consent_args)
      history_args = { reference_1: transaction.reference_1,
                       period_start: transaction.period_start,
                       period_end: transaction.period_end }
      invoice = find_historic_invoices(history_args).order(tcm_transaction_reference: :desc).first

      if invoice
        set_category(transaction, invoice, :green, "Supplementary credit", admin_lock: true)
      else
        no_historic_transaction({ id: transaction.id }, "Supplementary credit")
      end
    end

    def find_latest_historic_invoice(consent_args)
      find_historic_invoices(consent_args).order(period_end: :desc, tcm_transaction_reference: :desc).first
    end

    def find_historic_invoices(consent_args)
      regime.transaction_details.historic.invoices.where(consent_args)
    end

    def find_latest_historic_invoice_version(transaction)
      like_clause = make_permit_discharge_matcher(transaction.reference_1)
      at = TransactionDetail.arel_table
      regime
        .transaction_details
        .historic
        .invoices
        .where(at[:reference_1].matches(like_clause))
        .where(period_end: transaction.period_end)
        .order(reference_2: :desc, tcm_transaction_reference: :desc).first
    end

    def find_latest_historic_invoice_version_for_annual(transaction)
      like_clause = make_permit_discharge_matcher(transaction.reference_1)
      at = TransactionDetail.arel_table
      regime
        .transaction_details
        .historic
        .invoices
        .where(at[:reference_1].matches(like_clause))
        .order(period_end: :desc, reference_2: :desc, tcm_transaction_reference: :desc)
        .first
    end

    def consent_to_args(consent)
      { reference_1: consent }
    end

    def make_permit_discharge_matcher(consent_reference)
      m = %r{\A(.*)/(\d+)/(\d+)\z}.match(consent_reference)
      # make 'like' string from permit and discharge parts of consent reference
      raise "Badly formatted consent reference: '#{consent_reference}'" if m.nil?

      "#{m[1]}/%/#{m[3]}"
    end
  end
end
