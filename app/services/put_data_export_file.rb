# frozen_string_literal: true

class PutDataExportFile < ServiceObject
  include FileStorage

  attr_reader :filename

  def initialize(params = {})
    super()
    @filename = params.fetch(:filename)
  end

  def call
    # store data export file in S3 (or local in DEV mode)
    if File.exist? filename
      begin
        archive_file_store.store_file(filename, csv_path)

        @result = true
      rescue StandardError => e
        @result = false
        TcmLogger.notify(e)
      end
    else
      @result = false
      TcmLogger.error("Cannot store export file. Local File not found '#{filename}'")
    end
    self
  end

  private

  def csv_path
    File.join("csv", File.basename(filename))
  end
end
