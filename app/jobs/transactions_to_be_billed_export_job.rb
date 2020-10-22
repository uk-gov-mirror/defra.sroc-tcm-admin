# frozen_string_literal: true

class TransactionsToBeBilledExportJob < ApplicationJob
  queue_as :default

  def perform
    ActiveRecord::Base.connection_pool.with_connection do
      Regime.all.each do |regime|
        service = TransactionExportService.new(regime)
        regime.regions.each do |region|
          tmp = Tempfile.new
          tmp << service.export(regime_transactions(regime, region))
          tmp.rewind
          storage.store_file_in(:csv_export, tmp.path, file_path(regime, region))
          tmp.close
          tmp.unlink
        end
      end
    end
  rescue StandardError => e
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
