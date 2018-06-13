require "csv"

class TransactionExportService
  attr_reader :regime

  def initialize(regime)
    @regime = regime
  end

  def export(transactions, options = {})
    CSV.generate(options) do |csv|
      csv << regime_columns
      transactions.each do |transaction|
        csv << ExportFileFormat::Columns.map { |c| transaction.send(c) }
      end
    end
  end

  def export_history(transactions, options = {})
    CSV.generate(options) do |csv|
      csv << regime_history_columns
      transactions.each do |transaction|
        csv << ExportFileFormat::HistoryColumns.map { |c| transaction.send(c) }
      end
    end
  end

  def regime_columns
    ExportFileFormat::Columns.map { |c| c.to_s.humanize.titlecase }
  end

  def regime_history_columns
    ExportFileFormat::HistoryColumns.map { |c| c.to_s.humanize.titlecase }
  end
end
