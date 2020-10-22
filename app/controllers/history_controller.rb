# frozen_string_literal: true

class HistoryController < ApplicationController
  include ViewModelBuilder
  include QueryTransactions
  include CsvExporter
  include RegimeScope

  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    @view_model = build_history_view_model

    respond_to do |format|
      format.html do
        render partial: "table", locals: { view_model: @view_model } if request.xhr?
      end
      format.csv do
        export_data_user_check!
        result = BatchCsvExport.call(regime: @regime,
                                     query: @view_model.fetch_transactions)
        if result.success?
          set_streaming_headers
          self.response_body = result.csv_stream
        end
      end
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show; end

  private

  def present_transactions(transactions)
    Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                            total_count: transactions.total_count,
                            limit: transactions.limit_value,
                            offset: transactions.offset_value)
  end
end
