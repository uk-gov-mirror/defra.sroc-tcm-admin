# frozen_string_literal: true

class TransactionFilesController < ApplicationController
  include ViewModelBuilder
  include RegimeScope

  before_action :set_regime
  before_action :read_only_user_check!, only: [:create]

  def index
    @view_model = build_transaction_files_view_model
    respond_to do |format|
      format.html do
        render partial: "table", locals: { view_model: @view_model } if request.xhr?
      end
    end
  end

  # POST /regimes/:regime_id/transaction_files
  def create
    set_region
    file = exporter.export
    msg = "Successfully generated transaction file <b>#{file.filename}</b>"
    flash[:success] = msg
    # force page 1 on redirect to prevent possibile invalid page selection
    redirect_to regime_transactions_path(@regime, page: 1)
  end

  private

  # :nocov:
  def set_region
    # TODO: this could be defaulted to a user's region if there are
    # restrictions around this
    @region = params.fetch(:region, "")
  end
  # :nocov:

  def exporter
    @exporter ||= TransactionFileExporter.new(@regime, @region, current_user)
  end
end
