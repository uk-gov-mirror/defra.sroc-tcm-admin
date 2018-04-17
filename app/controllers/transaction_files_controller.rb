# frozen_string_literal: true

class TransactionFilesController < ApplicationController
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
    files = exporter.export
    names = files.map(&:filename)
    msg = "Successfully generated transaction #{'file'.pluralize(names.count)} "
    msg += names.map { |f| "<b>#{f}</b>" }.join(", ")
    flash[:success] = msg
    # flash[:success] = "Successfully generated transaction file <b>#{transaction_file.filename}</b>"
    redirect_to regime_transactions_path(@regime)
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
      @exporter ||= TransactionFileExporter.new(@regime, @region)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
