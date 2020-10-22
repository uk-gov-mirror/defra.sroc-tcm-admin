# frozen_string_literal: true

class ImportedTransactionFilesController < ApplicationController
  include ViewModelBuilder
  include RegimeScope

  before_action :set_regime, only: %i[index update]
  before_action :apply_transaction_header, only: %i[show edit]
  before_action :read_only_user_check!

  def index
    @view_model = build_imported_transaction_files_view_model
    respond_to do |format|
      format.html do
        render partial: "table", locals: { view_model: @view_model } if request.xhr?
      end
    end
  end

  def show; end

  def edit
    return if @file.can_be_removed?

    flash[:error] = "This file contains billed transactions and cannot be removed"
    redirect_to regime_imported_transaction_file_path(@regime, @file)
  end

  def update
    @file = transaction_header
    parms = transaction_header_params
    result = RemoveImportedTransactionFile.call(
      transaction_header: @file,
      remover: current_user,
      removal_reference: parms[:removal_reference],
      removal_reason: parms[:removal_reason]
    )

    if result.success?
      redirect_to regime_imported_transaction_file_path(@regime, @file),
                  notice: "Transaction file removed"
    else
      @file = result.transaction_header
      render :edit
    end
  end

  private

  def apply_transaction_header
    @file = TransactionHeaderPresenter.new transaction_header
  end

  def transaction_header
    set_regime
    @regime.transaction_headers.find(params[:id])
  end

  def transaction_header_params
    params.require(:transaction_header).permit(:removal_reference,
                                               :removal_reason)
  end
end
