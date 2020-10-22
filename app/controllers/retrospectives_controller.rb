# frozen_string_literal: true

class RetrospectivesController < ApplicationController
  include ViewModelBuilder
  include QueryTransactions
  include CsvExporter
  include RegimeScope

  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]
  before_action :redirect_if_waste

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    @view_model = build_retrospectives_view_model

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

  def redirect_if_waste
    redirect_to regime_transactions_path(@regime) if @regime.waste?
  end

  def present_transactions(transactions)
    Kaminari.paginate_array(presenter.wrap(transactions, current_user),
                            total_count: transactions.total_count,
                            limit: transactions.limit_value,
                            offset: transactions.offset_value)
  end

  def present_transactions_for_json(transactions, selected_region, regions)
    arr = present_transactions(transactions)
    {
      pagination: {
        current_page: arr.current_page,
        prev_page: arr.prev_page,
        next_page: arr.next_page,
        per_page: arr.limit_value,
        total_pages: arr.total_pages,
        total_count: arr.total_count
      },
      transactions: arr,
      selected_region: selected_region,
      regions: region_options(regions)
    }
  end

  def region_options(regions)
    regions.map { |r| { label: r, value: r } }
  end

  def financial_year_options(fy_list)
    fys = fy_list.map { |fy| { label: "#{fy[0..1]}/#{fy[2..3]}", value: fy } }
    fys = [{ label: "All", value: "" }] + fys if fys.count > 1
    fys
  end
end
