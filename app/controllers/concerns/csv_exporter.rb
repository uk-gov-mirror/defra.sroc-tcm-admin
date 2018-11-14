module CsvExporter
  extend ActiveSupport::Concern

  # :nocov:
  def csv_opts
    ts = Time.zone.now.strftime("%Y%m%d%H%M%S")
    {
      filename: "#{controller_name}_#{ts}.csv",
      type: :csv
    }
  end

  def csv
    @csv ||= TransactionExportService.new(@regime)
  end
  # :nocov:
end
