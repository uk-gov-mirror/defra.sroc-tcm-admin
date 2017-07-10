require "csv"

class TransactionFileHandler
  include TransactionFile

  def export(transaction, path)
    presenter = TransactionCsvPresenter.new(transaction)

    CSV.open(path, "wb", { write_headers: false, force_quotes: true }) do |csv|
      csv << presenter.header
      presenter.details.each do |d|
        csv << d
      end
      csv << presenter.trailer
    end
  rescue => e
    raise TransactionFileError, e
  end

  def import(path)
    header = nil

    CSV.foreach(path) do |row|
      record_type = row[Common::RecordType]

      if record_type == "H"
        if header.nil?
          file_type = row[Header::FileType]
          if file_type == "I"
            source = row[Header::FileSource]
            region = row[Header::Region]
            file_seq_no = row[Header::FileSequenceNumber]
            bill_run_id = row[Header::BillRunId]
            generated_at = row[Header::FileDate]

            header = TransactionHeader.create!(
              regime: Regime.find_by(name: source),
              feeder_source_code: source,
              region: region,
              file_sequence_number: file_seq_no,
              bill_run_id: bill_run_id,
              generated_at: generated_at
            )
          else
            raise TransactionFileError, "Not a transaction file!"
          end
        else
          raise TransactionFileError, "Header record already exists?!"
        end
      elsif record_type == "D"
        # detail record
        raise TransactionFileError, "Detail record but no header record" if header.nil?
        header.transaction_details.create(extract_detail(row))
      elsif record_type == "T"
        # trailer record
        raise TransactionFileError, "Trailer record but no header record" if header.nil?
        # pull totals from trailer record
        header.transaction_count = row[Trailer::RecordCount].to_i
        header.invoice_total = row[Trailer::DebitTotal].to_i
        header.credit_total = row[Trailer::CreditTotal].to_i
        header.save!
      end
    end
  end

  def extract_detail(row)
    data = {
      sequence_number: row[Common::SequenceNumber].to_i,
      customer_reference: row[Detail::CustomerReference],
      transaction_date: row[Detail::TransactionDate],
      transaction_type: row[Detail::TransactionType],
      transaction_reference: row[Detail::TransactionReference],
      related_reference: row[Detail::RelatedReference],
      currency_code: row[Detail::CurrencyCode],
      header_narrative: row[Detail::HeaderNarrative],
      line_amount: row[Detail::LineAmount].to_i,
      line_vat_code: row[Detail::LineVatCode],
      line_area_code: row[Detail::LineAreaCode],
      line_description: row[Detail::LineDescription],
      line_income_stream_code: row[Detail::LineIncomeStreamCode],
      line_context_code: row[Detail::LineContextCode],
      line_quantity: row[Detail::LineQuantity].to_i,
      unit_of_measure: row[Detail::LineUnitOfMeasure],
      unit_of_measure_price: row[Detail::LineUOMPrice].to_i
    }

    # Header attrs 1 - 10
    (1..10).each do |n|
      data["header_attr_#{n}".to_sym] = row[8 + n]
    end

    # Line attrs 1 - 15
    (1..15).each do |n|
      data["line_attr_#{n}".to_sym] = row[24 + n]
    end

    data
  end
end
