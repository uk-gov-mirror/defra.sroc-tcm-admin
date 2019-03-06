# frozen_string_literal: true

class PutExportFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    @local_path = params.fetch(:local_path)
    @remote_path = params.fetch(:remote_path)
  end

  def call
    # store file in ETL bucket
    etl_file_store.store_file(@local_path, export_path)
    @result = true
    self
  end

  private

  def export_path
    File.join("export", @remote_path)
  end
end
