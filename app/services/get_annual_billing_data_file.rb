# frozen_string_literal: true

class GetAnnualBillingDataFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    @remote_path = params.fetch(:remote_path)
    @local_path = params.fetch(:local_path)
  end

  def call
    archive_file_store.fetch_file(annual_billing_path, @local_path)
    @result = true
    self
  end

  private

  def annual_billing_path
    File.join("annual_billing_data", @remote_path)
  end
end
