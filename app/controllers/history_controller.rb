# frozen_string_literal: true

class HistoryController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    regions = transaction_store.history_regions
    @region = params.fetch(:region, '')
    @region = regions.first unless @region.blank? || regions.include?(@region)

    q = params.fetch(:search, "")
    fy = params.fetch(:fy, '')
    sort_col = params.fetch(:sort, :customer_reference)
    sort_dir = params.fetch(:sort_direction, 'asc')

    respond_to do |format|
      format.html do
        render
      end
      format.js
      format.json do
        pg = params.fetch(:page, 1)
        per_pg = params.fetch(:per_page, 10)

        @transactions = transaction_store.transaction_history(
          q,
          fy,
          pg,
          per_pg,
          @region,
          sort_col,
          sort_dir)

        financial_years = transaction_store.history_financial_years.reject { |r| r.blank? }
        @transactions = present_transactions(@transactions, @region, regions, financial_years)
        render json: @transactions
      end
      format.csv do
        @transactions = transaction_store.transaction_history_for_export(
          q,
          fy,
          @region,
          sort_col,
          sort_dir
        ).limit(15000)
        send_data csv.export_history(presenter.wrap(@transactions)), csv_opts
      end
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
  end

  private
    def csv_opts
      ts = Time.zone.now.strftime("%Y%m%d%H%M%S")
      {
        filename: "transaction_history_#{ts}.csv",
        type: :csv
      }
    end

    def present_transactions(transactions, selected_region, regions, financial_years)
      name = "#{@regime.slug}_transaction_detail_presenter".camelize
      presenter = str_to_class(name) || TransactionDetailPresenter
      arr = Kaminari.paginate_array(presenter.wrap(transactions),
                                    total_count: transactions.total_count,
                                    limit: transactions.limit_value,
                                    offset: transactions.offset_value)
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

    def financial_year_options(fy_list)
      fys = fy_list.map { |fy| { label: fy[0..1] + '/' + fy[2..3], value: fy } }
      fys = [{label: 'All', value: ''}] + fys if fys.count > 1
      fys
    end

    def csv
      @csv ||= TransactionExportService.new(@regime)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
