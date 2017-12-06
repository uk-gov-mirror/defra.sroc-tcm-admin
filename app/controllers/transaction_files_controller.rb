# frozen_string_literal: true

class TransactionFilesController < ApplicationController
  before_action :set_regime, only: [:index, :create]
  before_action :set_transaction_file, only: [:show, :edit, :update]

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
    # Accept and continue to create transaction file
    flash[:success] = "Successfully generated transaction file &lt;<b>FILE NAME HERE</b>&gt;"
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
    # Use callbacks to share common setup or constraints between actions.
    def set_regime
      # TODO: this is just to avoid not having a regime set on entry
      # this will be replaced by using user regimes roles/permissions
      if params.fetch(:regime_id, nil)
        @regime = Regime.find_by!(slug: params[:regime_id])
      else
        @regime = Regime.first
      end
    end

    def set_region
      # TODO: this could be defaulted to a user's region if there are
      # restrictions around this
      @region = params.fetch(:region, '')
    end
    # :nocov:

    def set_transaction_file
      set_regime
      @transaction_file = transaction_file_store.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_file_params
      params.require(:transaction_file).permit(:category)
    end

    def collate_summary
      transaction_store.transactions_to_be_billed_summary('', @region)
    end

    def transaction_store
      @transaction_store ||= TransactionStorageService.new(@regime)
    end
end
