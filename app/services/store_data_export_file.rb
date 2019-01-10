class StoreDataExportFile < ServiceObject

  attr_reader :regime, :filename

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @filename = params.fetch(:filename)
  end

  def call
    # store data export file in S3 (or local in DEV mode)
    if File.exists? filename
      basename = File.basename(filename)

      begin
        storage.store_file_in(:csv_export,
                              filename,
                              File.basename(filename))

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

  def storage
    @storage ||= FileStorageService.new
  end
end
