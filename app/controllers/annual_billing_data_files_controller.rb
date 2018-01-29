# frozen_string_literal: true

class AnnualBillingDataFilesController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index, :new, :create]
  before_action :set_upload, only: [:show, :edit, :update]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    # list of uploads
    @uploads = @regime.annual_billing_data_files.order(created_at: :desc)
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
    pg = params.fetch(:page, 1)
    per_pg = params.fetch(:per_page, 10)
    sort_col = params.fetch(:sort, :line_number)
    sort_dir = params.fetch(:sort_direction, 'asc')

    @errors = @upload.data_upload_errors.
      order(sort_col => sort_dir).page(pg).per(per_pg)

    respond_to do |format|
      format.html do
        @errors = present_errors(@errors)
        render
      end
      format.js
      format.json do
        render json: present_file(@upload, @errors)
      end
    end
    # if request.xhr?
    #   render '_upload_details', layout: false
    # end
  end

  # GET /regimes/:regimes_id/transactions/1/edit
  def edit
    # possible re-run matching and merging process?
  end

  # PATCH/PUT /regimes/:regimes_id/transactions/1
  # PATCH/PUT /regimes/:regimes_id/transactions/1.json
  def update
    # possible re-run matching and merging process?
  end

  def new
    @upload = data_service.new_upload
  end

  def create
    @upload = data_service.upload(file_params)

    if @upload.errors.empty? && @upload.save
      # start background job
      AnnualBillingDataImportJob.perform_later(@upload.id)
      # the show page will display progress while importing
      redirect_to regime_annual_billing_data_file_path(@regime, @upload)
    else
      render "new"
    end
  end

  private
    def set_upload
      set_regime
      @upload = data_service.find(params[:id])
    end

    def file_params
      params.require(:annual_billing_data_file).permit(:data_file)
    end

    def present_errors(errors)
      error_data = errors.map do |e|
        {
          id: e.id,
          line_number: e.line_number,
          message: e.message
        }
      end
      {
        errors: error_data,
        pagination: {
          current_page: errors.current_page,
          prev_page: errors.prev_page,
          next_page: errors.next_page,
          per_page: errors.limit_value,
          total_pages: errors.total_pages,
          total_count: errors.total_count
        }
      }
    end

    def present_file(upload, errors)
      {
        filename: File.basename(upload.filename),
        upload_date: helpers.formatted_date(upload.created_at, true),
        status: upload.status.humanize,
        success_count: upload.success_count,
        failed_count: upload.failed_count,
        error_list: present_errors(errors)
      }
    end

    def data_service
      @data_service ||= AnnualBillingDataFileService.new(@regime)
    end
end
