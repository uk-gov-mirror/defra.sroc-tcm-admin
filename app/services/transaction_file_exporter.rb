require "csv"

class TransactionFileExporter
  include TransactionFileFormat, TransactionGroupFilters

  attr_reader :regime, :region

  def initialize(regime, region)
    @regime = regime
    @region = region
  end

  def export
    f = nil
    # lock transactions for regime / region
    # get list of exportable transactions
    TransactionDetail.transaction do
      q = grouped_unbilled_transactions_by_region(region).lock(true)
      credit_total = q.credits.
        pluck("charge_calculation -> 'calculation' -> 'chargeValue'").sum
      invoice_total = q.invoices.
        pluck("charge_calculation -> 'calculation' -> 'chargeValue'").sum

      f = regime.transaction_files.create!(region: region,
                                           generated_at: Time.zone.now,
                                           credit_total: (-credit_total * 100).round,
                                           invoice_total: (invoice_total * 100).round)

      # link transactions and update status
      q.update_all(transaction_file_id: f.id, status: 'exporting')
    end

    # queue the background job to create the file
    FileExportJob.perform_later(f.id) unless f.nil?
    f
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
    assign_invoice_numbers(transaction_file)

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
    "#{regime.to_param.titlecase}#{file_type}FilePresenter".constantize.new(transaction_file)
    #
    # if transaction_file.retrospective?
    #   if regime.water_quality?
    #     CfdRetrospectiveFilePresenter.new(transaction_file)
    #   elsif regime.waste?
    #   else
    #   end
    # else
    #   if regime.water_quality?
    #     CfdTransactionFilePresenter.new(transaction_file)
    #   elsif regime.waste?
    #   else
    #   end
    # end
  end

  def assign_invoice_numbers(transaction_file)
    # for CFD group transactions by Customer Reference
    # generate invoice number and assign to group
    # calculate overall credit or invoice and assign to group
    cust_charges = if transaction_file.retrospective?
                     transaction_file.transaction_details.
                       group(:customer_reference).sum(:line_amount)
                   else
                     transaction_file.transaction_details.
                       group(:customer_reference).sum(:tcm_charge)
                   end

    cust_charges.each do |k, v|
      trans_type = v.negative? ? 'C' : 'I'
      n = SequenceCounter.next_invoice_number(regime, region)
      trans_ref = if transaction_file.retrospective?
                    "#{n.to_s.rjust(5, '0')}2#{region}"
                  else
                    "#{n.to_s.rjust(5, '0')}1#{region}T"
                  end
      transaction_file.transaction_details.where(customer_reference: k).
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
end
