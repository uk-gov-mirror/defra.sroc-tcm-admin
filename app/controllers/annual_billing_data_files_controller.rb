# frozen_string_literal: true

class AnnualBillingDataFilesController < ApplicationController
  include ViewModelBuilder
  include RegimeScope

  before_action :set_regime, only: %i[index new create]
  before_action :set_upload, only: %i[show edit update]

  # GET /regimes/:regime_id/transactions
  # GET /regimes/:regime_id/transactions.json
  def index
    # list of uploads
    @uploads = @regime.annual_billing_data_files.order(created_at: :desc)
  end

  # GET /regimes/:regime_id/transactions/1
  # GET /regimes/:regime_id/transactions/1.json
  def show
    @view_model = build_annual_billing_view_model

    respond_to do |format|
      format.html do
        if request.xhr?
          render partial: "table", locals: { view_model: @view_model }
        else
          render
        end
      end
    end
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
      AnnualBillingDataImportJob.perform_later(current_user.id, @upload.id)
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
      upload_date: helpers.formatted_date(upload.created_at, include_time: true),
      status: upload.status.humanize,
      success_count: upload.success_count,
      failed_count: upload.failed_count,
      error_list: present_errors(errors)
    }
  end

  def data_service
    @data_service ||= AnnualBillingDataFileService.new(@regime, current_user)
  end
end
