# frozen_string_literal: true

class ExclusionsController < ApplicationController
  include RegimeScope, CsvExporter, QueryTransactions, ViewModelBuilder

  before_action :read_only_user_check!
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/exclusions
  # GET /regimes/:regime_id/exclusions.json
  def index
    @view_model = build_exclusions_view_model

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: 'table', locals: { view_model: @view_model }
        end
      end
      format.csv do
        result = BatchCsvExport.call(regime: @regime,
                                     query: @view_model.fetch_transactions)
        if result.success?
          set_streaming_headers
          self.response_body = result.csv_stream
        end
        # set_streaming_headers
        # self.response_body = stream_csv_data(@view_model.fetch_transactions)
        # send_data csv.full_export(@view_model.csv_transactions), csv_opts
      end
    end
  end

  # GET /regimes/:regime_id/exclusions/1
  # GET /regimes/:regime_id/exclusions/1.json
  def show
  end

  private
    def set_streaming_headers
      ts = Time.zone.now.strftime("%Y%m%d%H%M%S")
      filename = "exclusions_#{ts}.csv"

      headers["Content-Type"] = "text/csv"
      headers["Content-disposition"] = "attachment; filename=\"#{filename}\""
      headers['X-Accel-Buffering'] = 'no'
      headers.delete("Content-Length")
    end

    def present_transactions(transactions)
      Kaminari.paginate_array(presenter.wrap(transactions),
                              total_count: transactions.total_count,
                              limit: transactions.limit_value,
                              offset: transactions.offset_value)
    end

    def present_transactions_for_json(transactions)
      regions = Query::Regions.call(regime: @regime)
      selected_region = params.fetch(:region, regions.first)
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
        regions: region_options(regions),
        financial_years: financial_year_options(financial_years)
      }
    end

    def region_options(regions)
      opts = regions.map { |r| { label: r, value: r } }
      opts = [{label: 'All', value: ''}] + opts if opts.count > 1
      opts
    end

    def financial_years
      Query::FinancialYears.call(regime: @regime)
    end

    def financial_year_options(fy_list)
      fys = fy_list.map { |fy| { label: fy[0..1] + '/' + fy[2..3], value: fy } }
      fys = [{label: 'All', value: ''}] + fys if fys.count > 1
      fys
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
