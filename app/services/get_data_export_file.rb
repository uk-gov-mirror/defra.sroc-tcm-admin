# frozen_string_literal: true

class GetDataExportFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    @remote_path = params.fetch(:remote_path)
    @local_path = params.fetch(:local_path)
  end

  def call
    archive_file_store.fetch_file(data_export_path, @local_path)
    @result = true
    self
  end

  private

  def data_export_path
    File.join("csv", @remote_path)
  end
end
