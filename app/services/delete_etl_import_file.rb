# frozen_string_literal: true

class DeleteEtlImportFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    @remote_path = params.fetch(:remote_path)
  end

  def call
    etl_file_store.delete_file(@remote_path)
    @result = true
    self
  end
end

