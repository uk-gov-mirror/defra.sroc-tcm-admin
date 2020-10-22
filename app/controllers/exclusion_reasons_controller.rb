# frozen_string_literal: true

class ExclusionReasonsController < AdminController
  include RegimeScope
  # allow billing admins access to the index (frontend JSON requests)
  skip_before_action :admin_only_check!, only: :index

  before_action :set_regime
  before_action :set_reason, only: %i[edit update destroy]

  def index
    @reasons = @regime.exclusion_reasons.order(:reason)
  end

  def show; end

  def new
    @reason = @regime.exclusion_reasons.build
  end

  def create
    @reason = @regime.exclusion_reasons.new(reason_params)

    if @reason.valid?
      @reason.save!
      redirect_to regime_exclusion_reasons_path(@regime), notice: "Exclusion reason created"
    else
      render :new
    end
  end

  def edit; end

  def update
    if @reason.update(reason_params)
      redirect_to regime_exclusion_reasons_path(@regime), notice: "Exclusion reason updated"
    else
      render :edit
    end
  end

  def destroy
    @reason.destroy
    redirect_to regime_exclusion_reasons_path(@regime), notice: "Exclusion reason deleted"
  end

  private

  def set_reason
    @reason = @regime.exclusion_reasons.find(params[:id])
  end

  def reason_params
    params.require(:exclusion_reason).permit(:reason, :active)
  end
end
