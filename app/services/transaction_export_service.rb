# frozen_string_literal: true

require "csv"

class TransactionExportService
  attr_reader :regime

  def initialize(regime)
    @regime = regime
  end

  def full_export(transactions, options = {})
    CSV.generate(options) do |csv|
      csv << batch_regime_headers
      transactions.each do |transaction|
        csv << batch_regime_columns.map { |c| transaction.send(c) }
      end
    end
  end

  def export(transactions, options = {})
    CSV.generate(options) do |csv|
      csv << regime_columns
      transactions.each do |transaction|
        csv << ExportFileFormat::COLUMNS.map { |c| transaction.send(c) }
      end
    end
  end

  def export_history(transactions, options = {})
    CSV.generate(options) do |csv|
      csv << regime_history_columns
      transactions.each do |transaction|
        csv << ExportFileFormat::HISTORY_COLUMNS.map { |c| transaction.send(c) }
      end
    end
  end

  def batch_regime_headers
    ExportFileFormat::EXPORT_COLUMNS.map { |c| c[:heading] }
  end

  def batch_regime_columns
    ExportFileFormat::EXPORT_COLUMNS.map { |c| c[:accessor] }
  end

  def regime_columns
    ExportFileFormat::COLUMNS.map { |c| c.to_s.humanize.titlecase }
  end

  def regime_history_columns
    ExportFileFormat::HISTORY_COLUMNS.map { |c| c.to_s.humanize.titlecase }
  end
end
