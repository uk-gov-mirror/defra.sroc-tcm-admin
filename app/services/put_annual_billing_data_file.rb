# frozen_string_literal: true

class PutAnnualBillingDataFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    super()
    @local_path = params.fetch(:local_path)
    @remote_path = params.fetch(:remote_path)
  end

  def call
    # store file in archive bucket
    archive_file_store.store_file(@local_path, annual_billing_path)
    @result = true
    self
  end

  private

  def annual_billing_path
    File.join("annual_billing_data", @remote_path)
  end
end
