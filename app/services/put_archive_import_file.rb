# frozen_string_literal: true

class PutArchiveImportFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    super()
    @local_path = params.fetch(:local_path)
    @remote_path = params.fetch(:remote_path)
  end

  def call
    archive_file_store.store_file(@local_path, @remote_path)
    @result = true
    self
  end
end
