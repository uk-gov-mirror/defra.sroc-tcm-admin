# frozen_string_literal: true

class TransactionFilesController < ApplicationController
  include RegimeScope

  # POST /regimes/:regime_id/transaction_files
  def create
    set_regime
    set_region
    transaction_file = exporter.export

    flash[:success] = "Successfully generated transaction file <b>#{transaction_file.filename}</b>"
    redirect_to regime_transactions_path(@regime)
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
end
