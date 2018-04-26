class FileExportJob < ApplicationJob
  queue_as :default

  def perform(transaction_file_id)
    ActiveRecord::Base.connection_pool.with_connection do
      transaction_file = TransactionFile.find(transaction_file_id)
      exporter = TransactionFileExporter.new(transaction_file.regime,
                                             transaction_file.region,
                                             transaction_file.user)
      exporter.generate_output_file(transaction_file)
    end
  rescue => e
    Rails.logger.error("FileExportJob: Failure: " + e.message)
  end
end
