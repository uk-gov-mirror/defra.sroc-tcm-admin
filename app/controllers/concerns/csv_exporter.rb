# frozen_string_literal: true

module CsvExporter
  extend ActiveSupport::Concern

  # :nocov:

  def set_streaming_headers
    headers["Content-Type"] = "text/csv"
    headers["Content-disposition"] = "attachment; filename=\"#{csv_filename}\""
    headers["X-Accel-Buffering"] = "no"
    headers.delete("Content-Length")
  end

  def csv_filename
    ts = Time.zone.now.strftime("%Y%m%d%H%M%S")
    "#{controller_name}_#{ts}.csv"
  end

  def csv_opts
    {
      filename: csv_filename,
      type: :csv
    }
  end

  def csv
    @csv ||= TransactionExportService.new(@regime)
  end
  # :nocov:
end
