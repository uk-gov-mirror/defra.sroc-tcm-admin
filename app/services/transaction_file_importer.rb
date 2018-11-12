require "csv"

class TransactionFileImporter
  include TransactionFileFormat

  def import(path, original_filename)
    header = nil
    process_retrospectives = SystemConfig.config.process_retrospectives?

    TransactionHeader.transaction do
      CSV.foreach(path) do |row|
        record_type = row[Common::RecordType]

        if record_type == "H"
          if header.nil?
            file_type = row[Header::FileType]
            if file_type == "I"
              source = row[Header::FileSource]
              region = row[Header::Region]
              file_type_flag = row[Header::FileType]
              file_seq_no = row[Header::FileSequenceNumber]
              bill_run_id = row[Header::BillRunId]
              generated_at = sanitize_date(row[Header::FileDate])

              header = TransactionHeader.create!(
                regime: Regime.find_by(name: source),
                feeder_source_code: source,
                region: region,
                file_type_flag: file_type_flag,
                file_sequence_number: file_seq_no,
                bill_run_id: bill_run_id,
                generated_at: generated_at,
                filename: original_filename
              )
            else
              raise Exceptions::TransactionFileError, "Not a transaction file!"
            end
          else
            raise Exceptions::TransactionFileError, "Header record already exists?!"
          end
        elsif record_type == "D"
          # detail record
          raise Exceptions::TransactionFileError, "Detail record but no header record" if header.nil?
          detail = extract_detail(header, row, process_retrospectives)
          raise Exceptions::TransactionFileError, "Detail record has no reference_1" if detail[:reference_1].nil?
          header.transaction_details.create(detail)
        elsif record_type == "T"
          # trailer record
          raise Exceptions::TransactionFileError, "Trailer record but no header record" if header.nil?
          # pull totals from trailer record
          header.transaction_count = row[Trailer::RecordCount].to_i
          header.invoice_total = row[Trailer::DebitTotal].to_i
          header.credit_total = row[Trailer::CreditTotal].to_i
          header.save!
        else
          raise Exceptions::TransactionFileError, "Unknown record type (expected 'H', 'D' or 'T'): [#{record_type}]"
        end
      end
    end
    header
  end

  def extract_detail(header, row, process_retrospectives)
    data = {
      sequence_number: row[Common::SequenceNumber].to_i,
      customer_reference: row[Detail::CustomerReference],
      transaction_date: sanitize_date(row[Detail::TransactionDate]),
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

    period = nil
    regime = header.regime
    if regime.installations?
      data.merge!({
        filename: row[Detail::Filename],
        reference_1: row[Detail::PermitReference],
        reference_2: row[Detail::OriginalPermitReference],
        reference_3: row[Detail::AbsOriginalPermitReference],
        customer_name: row[Detail::PasCustomerName]
      })
    elsif regime.water_quality?
      consent_parts = extract_consent_fields(row[Detail::LineDescription])
      data.merge!(consent_parts) unless consent_parts.empty?
      data.merge!({
        variation: extract_variation(row),
        customer_name: row[Detail::CfdCustomerName]
      })
    elsif regime.waste?
      line = row[Detail::LineDescription]
      ref = if row[Detail::TransactionType] == 'C'
              row[Detail::LineAttr2]
            else
              row[Detail::LineAttr3]
            end

      refs = {
        reference_1: ref,
        reference_2: line.split(':').last.strip,
        customer_name: row[Detail::WmlCustomerName]
      }
      cc = extract_charge_code(line)
      refs[:reference_3] = cc unless cc.nil?
      data.merge!(refs)
    end

    # Header attrs 1 - 10
    (1..10).each do |n|
      data["header_attr_#{n}".to_sym] = row[8 + n]
    end

    # Line attrs 1 - 15
    (1..15).each do |n|
      data["line_attr_#{n}".to_sym] = row[24 + n]
    end
    
    # period dates
    period = TcmUtils.extract_csv_period_dates(regime, row)
    if period.present?
      data["period_start"] = period[0]
      data["period_end"] = period[1]
      data["tcm_financial_year"] = determine_financial_year(period[0])

      if process_retrospectives && regime.retrospective_date?(period[1])
        data["status"] = 'retrospective'
      end
    end

    # original file details
    data["original_filename"] = header.file_reference
    data["original_file_date"] = header.generated_at

    data
  end

  def extract_consent_fields(consent_data)
    parts = {}
    if consent_data.present?
      # Consent data field could look like this:
      # Consent No - 1008/2/1
      # - or -
      # Authorisation No - WQD005215/1/1
      # - or -
      # Consent No - WIG 0226/1/1
      # - or -
      # Consent No - T/40/00817/O */1/2
      # - or -
      # Consent No - TS/18/25124/O   R/11/1

      m = /\A(?>\w+\s+\w+\s+-\s+)((?:.*)\/(\d+)\/(\d+))$\z/.match(consent_data)
      if m
        parts = {
          # consent
          reference_1: m[1],
          # version
          reference_2: m[2],
          # discharge
          reference_3: m[3]
        }
      end
    end
    parts
  end

  def extract_variation(row)
    v = row[Detail::LineAttr9]
    if v.blank?
      "100%"
    elsif v.ends_with?('%')
      v
    else
      "#{v}%"
    end
  end

  def extract_charge_code(description)
    m = /(?:Charge Code (\d+))/.match(description)
    m[1] if m
  end

  def determine_financial_year(date)
    y = date.month < 4 ? date.year - 1 : date.year
    y -= 2000 if y > 2000
    sprintf('%02d%02d', y, y + 1)
  end

  def sanitize_date(d)
    Date.parse(d)
  rescue ArguementError => e
    Rails.logger.warn("Invalid date in transaction file: #{d}") 
    nil
  end
end
