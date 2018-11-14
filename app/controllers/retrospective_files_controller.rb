# frozen_string_literal: true

class RetrospectiveFilesController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index, :create]

  # GET /regimes/:regime_id/transaction_files
  # GET /regimes/:regime_id/transaction_files.json
  def index
    # TODO: this could be a list of generated files
  end

  # GET /regimes/:regime_id/transaction_files/1
  # GET /regimes/:regime_id/transaction_files/1.json
  def show
    # TODO: this could be detail of one file
  end

  # GET /regimes/:regime_id/transaction_files/new
  # def new
  #   # This can be invoked from generate transaction file on TTBB
  #   set_region
  #   @summary = collate_summary
  # end

  # POST /regimes/:regime_id/transaction_files
  def create
    set_region
    retro_file = exporter.export_retrospectives

    # Accept and continue to create transaction file
    msg = "Successfully generated retrospective file <b>#{retro_file.filename}</b>"

    flash[:success] = msg
    # force page 1 on redirect to prevent possibile invalid page selection
    redirect_to regime_retrospectives_path(@regime, page: 1)
  end

  # GET /regimes/:regimes_id/transaction_files/1/edit
  def edit
  end

  # PATCH/PUT /regimes/:regimes_id/transaction_files/1
  def update
  end

  private
    # :nocov:
    def set_region
      # TODO: this could be defaulted to a user's region if there are
      # restrictions around this
      @region = params.fetch(:region, '')
    end
    # :nocov:

    def exporter
      @exporter ||= TransactionFileExporter.new(@regime, @region, current_user)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime, current_user)
    end
end
