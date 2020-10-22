# frozen_string_literal: true

class AnnualBillingDataImportJob < ApplicationJob
  queue_as :default

  def perform(user_id, upload_id)
    ActiveRecord::Base.connection_pool.with_connection do
      upload = AnnualBillingDataFile.includes(:regime).find(upload_id)
      user = User.find(user_id)

      regime = upload.regime
      data_service = AnnualBillingDataFileService.new(regime, user)

      # fetch stored file
      file = Tempfile.new

      GetAnnualBillingDataFile.call(remote_path: upload.filename,
                                    local_path: file.path)

      file.rewind

      # process stored file
      begin
        # update upload record status
        upload.state.process!

        data_service.import(upload, file.path)

        # update upload record status
        upload.state.complete!
      rescue StandardError => e
        Rails.logger.error("AnnualBillingDataImportJob: Unhandled error: #{e.message}")
        # update upload record status
        upload.state.error!
      ensure
        file.close
        file.unlink
      end
    end
  rescue StandardError => e
    Rails.logger.error("AnnualBillingDataImportJob: Failure: #{e.message}")
    throw e
  end
end
