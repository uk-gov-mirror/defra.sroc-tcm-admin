# frozen_string_literal: true

class RetrospectivesController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]
  before_action :set_transaction, only: [:show]

  # GET /regimes/:regime_id/history
  # GET /regimes/:regime_id/history.json
  def index
    regions = transaction_store.retrospective_regions
    @region = params.fetch(:region, regions.first)
    @region = regions.first unless regions.include? @region

    respond_to do |format|
      format.html do
        render
      end
      format.js
      format.json do
        q = params.fetch(:search, "")
        pg = params.fetch(:page, 1)
        per_pg = params.fetch(:per_page, 10)

        @transactions = transaction_store.retrospective_transactions(
          q,
          pg,
          per_pg,
          @region,
          params.fetch(:sort, :customer_reference),
          params.fetch(:sort_direction, 'asc'))

        @transactions = present_transactions(@transactions, @region, regions)
        render json: @transactions
      end
    end
  end

  # GET /regimes/:regime_id/history/1
  # GET /regimes/:regime_id/history/1.json
  def show
  end

  private
    def present_transactions(transactions, selected_region, regions)
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
        regions: region_options(regions)
      }
    end

    def region_options(regions)
      regions.map { |r| { label: r, value: r } }
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
