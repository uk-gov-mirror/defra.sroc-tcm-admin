class PutDataExportFile < ServiceObject
  include FileStorage

  attr_reader :filename

  def initialize(params = {})
    @filename = params.fetch(:filename)
  end

  def call
    # store data export file in S3 (or local in DEV mode)
    if File.exists? filename
      basename = File.basename(filename)

      begin
        archive_file_store.store_file(filename, csv_path)

        @result = true
      rescue => e
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
    File.join('csv', File.basename(filename))
  end
end
