# frozen_string_literal: true

require "csv"

class TransactionFileExporter
  include TransactionGroupFilters
  include TransactionFileFormat

  attr_reader :regime, :region, :user

  def initialize(regime, region, user)
    @regime = regime
    @region = region
    @user = user
    Thread.current[:current_user] = user
  end

  def export
    file = nil
    # lock transactions for regime / region
    # get list of exportable transactions
    TransactionDetail.transaction do
      q = grouped_unbilled_transactions_by_region(region).lock(true)
      credits = q.credits.pluck(:tcm_charge)
      invoices = q.invoices.pluck(:tcm_charge)

      credit_count = credits.count
      debit_count = invoices.count

      credit_total = credits.sum
      invoice_total = invoices.sum

      file = regime.transaction_files.create!(region: region,
                                              user: user,
                                              generated_at: Time.zone.now,
                                              credit_total: credit_total,
                                              invoice_total: invoice_total,
                                              credit_count: credit_count,
                                              debit_count: debit_count,
                                              net_total: invoice_total +
                                              credit_total)

      # link transactions and update status
      q.update_all(transaction_file_id: file.id, status: "exporting")
    end
    # 'remove' excluded transactions
    excluded_transactions_by_region(region).update_all(status: "excluded")
    # queue the background job to create the file
    FileExportJob.perform_later(file.id) unless file.nil?
    file
  end

  def export_retrospectives
    file = nil
    # lock transactions for regime / region
    # get list of exportable transactions
    TransactionDetail.transaction do
      q = retrospective_transactions_by_region(region).lock(true)
      credits = q.credits.pluck(:line_amount)
      invoices = q.invoices.pluck(:line_amount)
      credit_total = credits.sum
      invoice_total = invoices.sum
      credit_count = credits.count
      debit_count = invoices.count

      if credit_count.positive? || debit_count.positive?
        file = regime.transaction_files.create!(region: region,
                                                user: user,
                                                retrospective: true,
                                                generated_at: Time.zone.now,
                                                credit_total: credit_total,
                                                invoice_total: invoice_total,
                                                credit_count: credit_count,
                                                debit_count: debit_count,
                                                net_total: invoice_total +
                                                credit_total)

        # link transactions and update status
        q.update_all(transaction_file_id: file.id, status: "retro_exporting")
      end
    end

    # queue the background job to create the file
    FileExportJob.perform_later(file.id) unless file.nil?
    file
  end

  def generate_output_file(transaction_file)
    out_file = Tempfile.new
    assign_transaction_references(transaction_file)
    assign_category_descriptions(transaction_file)

    tf = present(transaction_file)

    # create file record
    CSV.open(out_file.path, "wb", force_quotes: true) do |csv|
      csv << tf.header
      tf.details { |row| csv << row }
      csv << tf.trailer
    end

    out_file.rewind
    # make footer
    # update transactions status
    # write file and copy to S3
    PutExportFile.call(local_path: out_file.path,
                       remote_path: tf.path)
    PutArchiveExportFile.call(local_path: out_file.path,
                              remote_path: tf.path)

    attrs = {
      generated_filename: tf.base_filename,
      generated_file_at: tf.generated_at
    }

    attrs[:status] = if tf.retrospective?
                       "retro_billed"
                     else
                       "billed"
                     end
    tf.transaction_details.update_all(attrs)
    tf.update_attributes(state: "exported")
  ensure
    out_file.close
  end

  def present(transaction_file)
    file_type = transaction_file.retrospective? ? "Retrospective" : "Transaction"
    "#{regime.to_param.titlecase}#{file_type}FilePresenter".constantize.new(transaction_file)
  end

  def assign_category_descriptions(transaction_file)
    # retrospective files don't have categories
    return if transaction_file.retrospective?

    TransactionFile.transaction do
      transaction_file.transaction_details.each do |td|
        cat = permit_store.code_for_financial_year(td.category,
                                                   td.tcm_financial_year)
        td.update_attributes(category_description: cat.description)
      end
    end
  end

  def assign_transaction_references(transaction_file)
    send "assign_#{regime.to_param}_transaction_references", transaction_file
  end

  def assign_wml_transaction_references(transaction_file)
    # All transactions which are subject to a common permit reference and
    # a common sign in the line amount in the TCM-generated transaction file
    # should also be subject to a common invoice number in that file.
    # For SRoC transactions, this number should take the format RNNNNNNNNT, where:
    #
    # o 'R' is the region indicator from header field 4
    # o 'NNNNNNNN' is an 8-digit sequential number
    # o 'T' is a fixed digit
    #
    # E.g. the first invoice number for region A would be A00000001T, and so on.
    # The 'T' suffix should ensure that there will never be any duplication with
    # invoice numbers previously generated in WaBS
    atab = TransactionDetail.arel_table
    Query::TransactionFileYears.call(transaction_file: transaction_file).each do |fy|
      q = transaction_file.transaction_details.where(tcm_financial_year: fy)
      positives = q.distinct.where(atab[:tcm_charge].gteq(0)).pluck(:reference_1, :customer_reference)
      negatives = q.distinct.where(atab[:tcm_charge].lt(0)).pluck(:reference_1, :customer_reference)

      positives.each do |refs|
        ref, cust = refs
        trans_ref = next_wml_transaction_reference
        q.where(reference_1: ref).where(customer_reference: cust).where(atab[:tcm_charge].gteq(0))
         .update_all(tcm_transaction_type: "I",
                     tcm_transaction_reference: trans_ref)
      end
      negatives.each do |refs|
        ref, cust = refs
        trans_ref = next_wml_transaction_reference
        q.where(reference_1: ref).where(customer_reference: cust).where(atab[:tcm_charge].lt(0))
         .update_all(tcm_transaction_type: "C",
                     tcm_transaction_reference: trans_ref)
      end
    end
  end

  def next_wml_transaction_reference
    result = NextWmlReference.call(regime: regime, region: region)
    if result.success?
      result.reference
    else
      ""
    end
  end

  def assign_pas_transaction_references(transaction_file)
    # All transactions which are subject to a common permit reference and a
    # common sign in the line amount in the TCM-generated transaction file
    # should also be subject to a common invoice number in that file.
    # For SRoC transactions, this number should take the format PASNNNNNNNNRT,
    # where:
    # - 'NNNNNNNN' is an 8-digit sequential number
    # - 'R' is the region indicator from header field 4
    # - 'T' is a fixed digit
    # E.g. the first invoice number for region A would be PAS00000001AT, and so on.
    # The 'T' suffix should ensure that there will never be any duplication with
    # invoice numbers previously generated in PAS
    retro = transaction_file.retrospective?
    charge_attr = retro ? :line_amount : :tcm_charge
    atab = TransactionDetail.arel_table
    Query::TransactionFileYears.call(transaction_file: transaction_file).each do |fy|
      q = transaction_file.transaction_details.where(tcm_financial_year: fy)
      positives = q.distinct.where(atab[charge_attr].gteq(0)).pluck(:reference_1, :customer_reference)
      negatives = q.distinct.where(atab[charge_attr].lt(0)).pluck(:reference_1, :customer_reference)

      positives.each do |refs|
        ref, cust = refs
        trans_ref = next_pas_transaction_reference(retro)
        q.where(reference_1: ref).where(customer_reference: cust).where(atab[charge_attr].gteq(0))
         .update_all(tcm_transaction_type: "I",
                     tcm_transaction_reference: trans_ref)
      end
      negatives.each do |refs|
        ref, cust = refs
        trans_ref = next_pas_transaction_reference(retro)
        q.where(reference_1: ref).where(customer_reference: cust).where(atab[charge_attr].lt(0))
         .update_all(tcm_transaction_type: "C",
                     tcm_transaction_reference: trans_ref)
      end
    end
  end

  def next_pas_transaction_reference(retrospective)
    result = if retrospective
               NextPasRetrospectiveReference.call(regime: regime, region: region)
             else
               NextPasReference.call(regime: regime, region: region)
             end
    if result.success?
      result.reference
    else
      ""
    end
  end

  def assign_cfd_transaction_references(transaction_file)
    # for CFD group transactions by Customer Reference
    # generate invoice number and assign to group
    # calculate overall credit or invoice and assign to group
    retro = transaction_file.retrospective?
    Query::TransactionFileYears.call(transaction_file: transaction_file).each do |fy|
      q = transaction_file.transaction_details.where(tcm_financial_year: fy)
      cust_charges = if retro
                       q.group(:customer_reference, :line_context_code).sum(:line_amount)
                     else
                       q.group(:customer_reference, :line_context_code).sum(:tcm_charge)
                     end

      cust_charges.each do |k, v|
        trans_type = v.negative? ? "C" : "I"
        trans_ref = next_cfd_transaction_reference(retro)

        q.where(customer_reference: k[0], line_context_code: k[1])
         .update_all(tcm_transaction_type: trans_type,
                     tcm_transaction_reference: trans_ref)
      end
    end
  end

  def next_cfd_transaction_reference(retrospective)
    result = if retrospective
               NextCfdRetrospectiveReference.call(regime: regime, region: region)
             else
               NextCfdReference.call(regime: regime, region: region)
             end
    if result.success?
      result.reference
    else
      ""
    end
  end

  def permit_store
    @permit_store ||= PermitStorageService.new(regime)
  end
end
