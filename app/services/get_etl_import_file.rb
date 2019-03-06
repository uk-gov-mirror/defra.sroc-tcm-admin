# frozen_string_literal: true

class GetEtlImportFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    @remote_path = params.fetch(:remote_path)
    @local_path = params.fetch(:local_path)
  end

  def call
    etl_file_store.fetch_file(@remote_path, @local_path)
    @result = true
    self
  end
end
