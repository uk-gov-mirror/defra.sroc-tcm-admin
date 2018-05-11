require "csv"

class TransactionFileExporter
  include TransactionFileFormat, TransactionGroupFilters

  attr_reader :regime, :region, :user

  def initialize(regime, region, user)
    @regime = regime
    @region = region
    @user = user
    Thread.current[:current_user] = user
  end

  def export
    files = []
    # lock transactions for regime / region
    # get list of exportable transactions
    TransactionDetail.transaction do
      q = grouped_unbilled_transactions_by_region(region).lock(true)

      # can't do a distinct query once locked for update, so have to do it locally
      # q.order(:tcm_financial_year).distinct.pluck(:tcm_financial_year).each do |fy|
      q.pluck(:tcm_financial_year).uniq.sort.each do |fy|
        fy_q = q.financial_year(fy)
        credit_total = fy_q.credits.pluck(:tcm_charge).sum
        invoice_total = fy_q.invoices.pluck(:tcm_charge).sum

        f = regime.transaction_files.create!(region: region,
                                             user: user,
                                             generated_at: Time.zone.now,
                                             credit_total: credit_total,
                                             invoice_total: invoice_total)

        # link transactions and update status
        fy_q.update_all(transaction_file_id: f.id, status: 'exporting')
        files << f
        # auditor.log_create(f)
      end
    end

    # queue the background job to create the file
    files.each do |file|
      FileExportJob.perform_later(file.id)
    end
    files
  end

  def export_retrospectives
    f = nil
    # lock transactions for regime / region
    # get list of exportable transactions
    TransactionDetail.transaction do
      q = retrospective_transactions_by_region(region).lock(true)
      credits = q.credits.pluck(:line_amount)
      invoices = q.invoices.pluck(:line_amount)
      credit_total = credits.sum
      invoice_total = invoices.sum

      if credits.count > 0 || invoices.count > 0
        f = regime.transaction_files.create!(region: region,
                                             user: user,
                                             retrospective: true,
                                             generated_at: Time.zone.now,
                                             credit_total: credit_total,
                                             invoice_total: invoice_total)

        # link transactions and update status
        q.update_all(transaction_file_id: f.id, status: 'retro_exporting')
      end
    end

    # queue the background job to create the file
    FileExportJob.perform_later(f.id) unless f.nil?
    f
  end

  def generate_output_file(transaction_file)
    out_file = Tempfile.new
    assign_transaction_references(transaction_file)

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
    storage.store_file_in(:export, out_file.path, tf.path)
    storage.store_file_in(:export_archive, out_file.path, tf.path)

    attrs = {
      generated_filename: tf.base_filename,
      generated_file_at: tf.generated_at
    }

    if tf.retrospective?
      attrs[:status] = 'retro_billed'
    else
      attrs[:status] = 'billed'
    end

    tf.transaction_details.update_all(attrs)
    tf.update_attributes(state: 'exported')
  ensure
    out_file.close
  end

  def present(transaction_file)
    file_type = transaction_file.retrospective? ? 'Retrospective' : 'Transaction'
    "#{regime.to_param.titlecase}#{file_type}FilePresenter".constantize.
      new(transaction_file)
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
    # o ‘R’ is the region indicator from header field 4
    # o ‘NNNNNNNN’ is an 8-digit sequential number
    # o ‘T’ is a fixed digit
    #
    # E.g. the first invoice number for region A would be A00000001T, and so on.
    # The ‘T’ suffix should ensure that there will never be any duplication with
    # invoice numbers previously generated in WaBS
    atab = TransactionDetail.arel_table
    positives = transaction_file.transaction_details.distinct.
      where(atab[:tcm_charge].gteq(0)).pluck(:reference_1)
    negatives = transaction_file.transaction_details.distinct.
      where(atab[:tcm_charge].lt(0)).pluck(:reference_1)

    positives.each do |ref|
      trans_ref = next_wml_transaction_reference
      transaction_file.transaction_details.where(reference_1: ref).
        where(atab[:tcm_charge].gteq(0)).
        update_all(tcm_transaction_type: 'I',
                   tcm_transaction_reference: trans_ref)
    end
    negatives.each do |ref|
      trans_ref = next_wml_transaction_reference
      transaction_file.transaction_details.where(reference_1: ref).
        where(atab[:tcm_charge].lt(0)).
        update_all(tcm_transaction_type: 'C',
                   tcm_transaction_reference: trans_ref)
    end
  end

  def next_wml_transaction_reference
    n = SequenceCounter.next_invoice_number(regime, region)
    "#{region}#{n.to_s.rjust(8, '0')}T"
  end

  def assign_pas_transaction_references(transaction_file)
    # All transactions which are subject to a common permit reference and a
    # common sign in the line amount in the TCM-generated transaction file
    # should also be subject to a common invoice number in that file.
    # For SRoC transactions, this number should take the format PASNNNNNNNNRT,
    # where:
    # - ‘NNNNNNNN’ is an 8-digit sequential number
    # - ‘R’ is the region indicator from header field 4
    # - ‘T’ is a fixed digit
    # E.g. the first invoice number for region A would be PAS00000001AT, and so on.
    # The ‘T’ suffix should ensure that there will never be any duplication with
    # invoice numbers previously generated in PAS  
    charge_attr = transaction_file.retrospective? ? :line_amount : :tcm_charge
    atab = TransactionDetail.arel_table
    positives = transaction_file.transaction_details.distinct.
      where(atab[charge_attr].gteq(0)).pluck(:reference_1)
    negatives = transaction_file.transaction_details.distinct.
      where(atab[charge_attr].lt(0)).pluck(:reference_1)

    positives.each do |ref|
      trans_ref = next_pas_transaction_reference(transaction_file.retrospective?)
      transaction_file.transaction_details.where(reference_1: ref).
        where(atab[charge_attr].gteq(0)).
        update_all(tcm_transaction_type: 'I',
                   tcm_transaction_reference: trans_ref)
    end
    negatives.each do |ref|
      trans_ref = next_pas_transaction_reference(transaction_file.retrospective?)
      transaction_file.transaction_details.where(reference_1: ref).
        where(atab[charge_attr].lt(0)).
        update_all(tcm_transaction_type: 'C',
                   tcm_transaction_reference: trans_ref)
    end
  end

  def next_pas_transaction_reference(retrospective)
    n = SequenceCounter.next_invoice_number(regime, region)
    if retrospective
      "PAS#{n.to_s.rjust(8, '0')}#{region}"
    else
      "PAS#{n.to_s.rjust(8, '0')}#{region}T"
    end
  end

  def assign_cfd_transaction_references(transaction_file)
    # for CFD group transactions by Customer Reference
    # generate invoice number and assign to group
    # calculate overall credit or invoice and assign to group
    cust_charges = if transaction_file.retrospective?
                     transaction_file.transaction_details.
                       group(:customer_reference, :line_context_code).sum(:line_amount)
                   else
                     transaction_file.transaction_details.
                       group(:customer_reference, :line_context_code).sum(:tcm_charge)
                   end

    cust_charges.each do |k, v|
      trans_type = v.negative? ? 'C' : 'I'
      n = SequenceCounter.next_invoice_number(regime, region)
      trans_ref = if transaction_file.retrospective?
                    "#{n.to_s.rjust(5, '0')}2#{region}"
                  else
                    "#{n.to_s.rjust(5, '0')}1#{region}T"
                  end
      transaction_file.transaction_details.where(customer_reference: k[0], line_context_code: k[1]).
        update_all(tcm_transaction_type: trans_type,
                   tcm_transaction_reference: trans_ref)
    end
  end

  def service
    @service ||= TransactionStorageService.new(regime)
  end

  def storage
    @storage ||= FileStorageService.new
  end

  # def auditor
  #   @auditor ||= AuditService.new(user)
  # end
end
