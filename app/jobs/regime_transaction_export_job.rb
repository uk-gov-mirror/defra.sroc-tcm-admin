class RegimeTransactionExportJob < ApplicationJob
  queue_as :default

  def perform(regime_id)
    ActiveRecord::Base.connection_pool.with_connection do
      regime = Regime.find(regime_id)
      result = ExportTransactionData.call(regime: regime,
                                          batch_size: 1000)
      if result.failed?
        TcmLogger.error("Failed to export transactions for #{regime.name}")
      else
        # store file
        result = StoreDataExportFile.call(regime: regime,
                                          filename: result.filename)
        TcmLogger.error("Failed to store export data file for #{regime.name}") if result.failed?
      end
    end
  rescue => e
    TcmLogger.notify(e)
  end

private
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
