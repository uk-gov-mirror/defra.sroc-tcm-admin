require 'csv'

class BatchCsvExport < ServiceObject
  include RegimePresenter

  attr_reader :regime, :query, :csv_stream, :max_limit, :batch_size

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @query = params.fetch(:query)
    @max_limit = params.fetch(:max_limit, 15000)
    @batch_size = params.fetch(:batch_size, 1000)
    @csv_stream = nil
  end

  def call
    @csv_stream = Enumerator.new do |y|
      y << csv_headers

      batch_query do |t|
        y << csv_row(t)
      end 
    end

    @result = true
    self
  end

  private

  def batch_query(&block)
    count = query.count
    count = [ count, max_limit ].min unless max_limit.zero?

    offset = 0
    while offset < count do
      query.offset(offset).limit(batch_size).each do |transaction|
        yield transaction
      end
      offset += batch_size
    end
  end

  def csv_headers
    CSV::Row.new(regime_columns, regime_headings, true).to_s
  end

  def csv_row(transaction)
    t = presenter.new(transaction)
    values = regime_columns.map { |c| t.send(c) }
    CSV::Row.new(regime_columns, values).to_s
  end

  def regime_headings
    ExportFileFormat::ExportColumns.map { |c| c[:heading] }
  end

  def regime_columns
    @regime_columns ||= ExportFileFormat::ExportColumns.map { |c| c[:accessor] }
  end
end
