require 'csv'

class ExportTransactionData < ServiceObject
  include RegimePresenter

  attr_reader :regime, :compress, :batch_size, :filename

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @compress = params.fetch(:compress, false)
    @batch_size = params.fetch(:batch_size, 1000)
  end

  def call
    # export all transactions to csv for the given regime
    p = presenter
    # batch results
    edf = regime.export_data_file
    edf.generating!
    begin
      ExportDataFile.transaction do
        regime_file do |csv|
          # csv << regime_headers
          batch_transactions(batch_size) do |transaction|
          # transactions.find_each(batch_size: batch_size) do |transaction|
            t = presenter.new(transaction)
            csv << regime_columns.map { |c| t.send(c) }
          end
        end
      end
      ext_compress_file if compress

      edf.update_attributes!(last_exported_at: Time.zone.now)
      edf.success!
      @result = true
    rescue => e
      TcmLogger.notify(e)
      edf.failed!
      @result = false
    end
    self
  end

  private

  def transactions
    regime.
      transaction_details.
      includes(:suggested_category,
               :transaction_header,
               :transaction_file).
      # eager_load(:suggested_category).
      order(:region).
      order(:transaction_date).
      order(:id)
  end

  def batch_transactions(batch_size = 1000, &block)
    # We need to be mindful that this is all transaction records
    # for the regime and will grow so we need to batch query or we
    # will quickly run out of memory on the server.
    # However, ActiveRecord#find_each ignores any order clause
    # (it uses :id only) so we are rolling our own here
    query = transactions
    count = query.count
    offset = 0
    while offset < count do
      query.offset(offset).limit(batch_size).each do |transaction|
        yield transaction
      end
      offset += batch_size
    end
  end

  def regime_file(&block)
    CSV.open(regime_filename, 'w', write_headers: true, headers: regime_headers) do |csv|
      yield csv
    end
  end

  def compress_file
    orig_file = regime_filename
    zip_file = "#{orig_file}.gz"
    Zlib::GzipWriter.open(zip_file) do |gz|
      gz.mtime = File.mtime(orig_file)
      gz.orig_name = orig_file
      gz.write IO.binread(orig_file)
    end
    @filename = zip_file
    File.delete(orig_file) if File.exist?(orig_file)
  rescue => e
    TcmLogger.notify(e)
    @filename = orig_file
  end

  def ext_compress_file
    # run gzip on the console
    orig_file = regime_filename
    zip_file = "#{orig_file}.gz"
    r = `gzip -fq #{orig_file}`
    @filename = zip_file
  rescue => e
    TcmLogger.notify(e)
    @filename = orig_file
  end

  def regime_headers
    ExportFileFormat::ExportColumns.map { |c| c[:heading] }
  end

  def regime_columns
    ExportFileFormat::ExportColumns.map { |c| c[:accessor] }
  end

  def regime_filename
    @filename ||= Rails.root.join('tmp', regime.export_data_file.filename).to_s
  end
end
