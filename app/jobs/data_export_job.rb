class DataExportJob < ApplicationJob
  queue_as :default

  def perform()
    ActiveRecord::Base.connection_pool.with_connection do
      Regime.all.each do |regime|
        result = ExportTransactionData.call(regime: regime,
                                            batch_size: 1000)
        if result.failed?
          TcmLogger.error("Failed to export transactions for #{regime.name}")
        else
          # move file to s3
          storage.store_file_in(:csv_export,
                                result.filename,
                                File.basename(result.filename))
        end
      end
    end
  rescue => e
    TcmLogger.notify(e)
  end

private
  def storage
    @storage ||= FileStorageService.new
  end

  def file_path(regime, region)
    "transactions_to_be_billed/#{regime.to_param}_#{region}.csv"
  end

  def regime_transactions(regime, region)
    q = regime.transaction_details.region(region).unbilled
    if regime.water_quality?
      CfdTransactionDetailPresenter.wrap(q)
    elsif regime.installations?
      PasTransactionDetailPresenter.wrap(q)
    elsif regime.waste?
      WmlTransactionDetailPresenter.wrap(q)
    else
      raise "Unknown regime: #{regime.to_param}"
    end
  end
end

