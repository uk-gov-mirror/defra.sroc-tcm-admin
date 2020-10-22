# frozen_string_literal: true

# Moves a file from the ETL bucket to the Archive bucket quarantine folder
class PutQuarantineFile < ServiceObject
  include FileStorage

  def initialize(params = {})
    super()
    @local_path = params.fetch(:local_path)
    @remote_path = params.fetch(:remote_path)
  end

  def call
    archive_file_store.store_file(@local_path, quarantine_path)
    @result = true
    self
  end

  private

  def quarantine_path
    File.join("quarantine", File.basename(@remote_path))
  end
end
