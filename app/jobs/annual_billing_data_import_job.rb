class AnnualBillingDataImportJob < ApplicationJob
  queue_as :default

  def perform(upload_id)
    ActiveRecord::Base.connection_pool.with_connection do
      upload = AnnualBillingDataFile.includes(:regime).find(upload_id)

      regime = upload.regime
      storage = FileStorageService.new
      data_service = AnnualBillingDataFileService.new(regime)

      # fetch stored file
      file = Tempfile.new
      storage.fetch_file_from(:annual_billing_data, upload.filename, file.path)
      file.rewind

      # process stored file
      begin
        # update upload record status
        upload.state.process!

        data_service.import(upload, file.path)

        # update upload record status
        upload.state.complete!
      rescue => e
        Rails.logger.error("AnnualBillingDataImportJob: Unhandled error: " + e.message)
        # update upload record status
        upload.state.error!
      ensure
        file.close
        file.unlink
      end
    end
  rescue => e
    Rails.logger.error("AnnualBillingDataImportJob: Failure: " + e.message)
    throw e
  end
end
