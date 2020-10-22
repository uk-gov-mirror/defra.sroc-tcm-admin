# frozen_string_literal: true

require "csv"

class AnnualBillingDataFileService
  include RegimeScope
  include AnnualBillingDataFileFormat

  attr_reader :regime, :user

  def initialize(regime, user)
    @regime = regime
    @user = user
  end

  def new_upload(params = {})
    regime.annual_billing_data_files.build(params)
  end

  def find(id)
    regime.annual_billing_data_files.find(id)
  end

  def upload(params = {})
    record = regime.annual_billing_data_files.build(number_of_records: 0,
                                                    status: "new")
    data_file = params.fetch(:data_file, nil)
    if data_file
      if valid_file? data_file.tempfile
        begin
          # upload to S3
          filename = File.basename(data_file.original_filename)
          dest_file = File.join(storage_path, filename)
          PutAnnualBillingDataFile.call(local_path: data_file.tempfile.path,
                                        remote_path: dest_file)

          record.filename = dest_file
          record.state.upload!
        rescue StandardError => e
          record.errors.add(:base, e.message)
        end
      else
        record.errors.add(:base, "This file type is not supported.  " \
                          "Please upload a correctly formatted CSV " \
                          "file (.csv)")
      end
    else
      record.errors.add(:base, "Select a annual billing data file (.csv) " \
                        "to import")
    end
    record
  end

  def valid_file?(file)
    # check file looks reasonable
    csv = CSV.new(file,
                  headers: true,
                  return_headers: true,
                  header_converters: lambda { |h|
                                       TcmUtils.strip_bom(h).parameterize.underscore.to_sym
                                     },
                  field_size_limit: 32)
    csv.shift
    headers = csv.headers
    valid = true
    mandatory_headers.each { |h| valid = false unless headers.include? h }
    valid
  rescue CSV::MalformedCSVError => e
    Rails.logger.warn(e.message)
    false
  rescue StandardError => e
    Rails.logger.error(e.message)
    false
  end

  def mandatory_headers
    send("#{regime.to_param}_mandatory_column_names")
  end

  def regime_headers
    send("#{regime.to_param}_columns")
  end

  def storage_path
    File.join(regime.to_param, Time.zone.now.strftime("%Y%m%d%H%M%S"))
  end

  def import(upload, path)
    set_current_user
    headers = regime_headers
    key_header = headers.select { |h| h.fetch(:unique_reference, false) }.first
    key_column = key_header[:header]
    ref_column = key_header[:column]
    update_columns = headers.reject { |h| h[:header] == key_column }

    counter = 1
    CSV.foreach(path, headers: true,
                      header_converters: lambda { |h|
                                           TcmUtils.strip_bom(h).parameterize.underscore.to_sym
                                         },
                      field_size_limit: 32) do |row|
      counter += 1
      failed = false
      ref_value = row.fetch(key_column)

      transaction = find_matching_transaction(upload, counter, key_column,
                                              ref_column, ref_value)

      if transaction.nil?
        # errors logged in #find_matching_transaction
        failed = true
      else
        # we have a transaction
        update_columns.each do |col|
          next if failed

          val = row.fetch(col[:header], nil)

          if val.blank? && col[:mandatory]
            upload.log_error(counter, "No value for mandatory field #{present_column(col[:header])}")
            failed = true
          elsif val.present?
            case col[:header]
            when :permit_category
              # validate against categories first
              # this needs to be against the new way of working now
              # if !regime.permit_categories.where(code: val).exists
              failed = !Query::PermitCategoryExists.call(regime: @regime,
                                                         category: val,
                                                         financial_year: transaction.tcm_financial_year)
            when :variation
              # check it's a positive number between 0 - 100
              # will always be an integer as they round down any fractional values
              begin
                i = Integer(val.to_s, 10)
                raise ArgumentError if i.negative? || i > 100

                val += "%" unless val.include?("%")
              rescue ArgumentError
                failed = true
              end
            when :temporary_cessation
              # check for Y or N
              v = val.downcase
              if v != "y" && v != "n"
                failed = true
              else
                val = (v == "y")
              end
            end

            if failed
              upload.log_error(counter, "Invalid #{present_column(col[:header])} value: '#{val}'")
            else
              transaction.send("#{col[:column]}=", val)
            end
          end
        end

        unless failed
          if transaction.changed?
            # (re)calculate the charge if the transaction has changed
            transaction.charge_calculation = CalculateCharge.call(transaction: transaction).charge_calculation
            if transaction.charge_calculation_error?
              # what should we do here? revoke the changes and mark as an error?
              upload.log_error(counter,
                               "Calculation error: #{TransactionCharge.extract_calculation_error(transaction)}")
              failed = true
            else
              transaction.tcm_charge = TransactionCharge.extract_correct_charge(transaction)
              if transaction.save
                upload.success_count += 1
              else
                upload.log_error(counter, upload.errors.full_messages.join(", "))
                failed = true
              end
            end
          else
            # changes didn't affect the transaction values already set
            upload.success_count += 1
          end
        end
      end
      upload.failed_count += 1 if failed
      upload.save
    end
  end

  def find_matching_transaction(upload, line_no, key_column, ref_column, ref_value)
    transactions = regime.transaction_details.unbilled.where(ref_column => ref_value).order(:updated_at)

    if transactions.count.zero?
      upload.log_error(line_no, "Could not find #{present_column(key_column)} matching '#{ref_value}'")
      nil
    elsif regime.water_quality? && transactions.count > 1
      # cannot have duplicates for WQ - apparently consent references are
      # only unique within a region not the regime - so possible duplicates could
      # be found although this would be an error and shouldn't happen we need
      # to cater for the possiblity...
      regions = regions_for_transactions(transactions)

      column_name = present_column(key_column)
      region_count = "region".pluralize(regions.count)

      upload.log_error(
        line_no,
        "Multiple transactions found for #{column_name}: '#{ref_value}' in #{region_count} #{regions.join(', ')}"
      )
      nil
    else
      # if multiple matches, it apparently doesn't matter which one we select,
      # but to ensure the all get updated if there are multiple in the import
      # file, always select the oldest modified one to update
      transactions.first
    end
  end

  def regions_for_transactions(list)
    TransactionHeader.where(id: list.pluck(:transaction_header_id).uniq).pluck(:region).uniq.sort
  end

  def set_current_user
    # so we can pick up the user for auditing changes
    Thread.current[:current_user] = user
  end
end
