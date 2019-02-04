class DataExportJob < ApplicationJob
  queue_as :default

  def perform()
    ActiveRecord::Base.connection_pool.with_connection do
      Regime.all.each do |regime|
        # enqueue an export job for each regime
        RegimeTransactionExportJob.perform_later(regime.id)
      end
    end
  rescue => e
    TcmLogger.notify(e)
  end
end
