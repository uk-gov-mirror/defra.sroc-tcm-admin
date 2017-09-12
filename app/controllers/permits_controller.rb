# frozen_string_literal: true

class PermitsController < ApplicationController
  before_action :set_regime, only: [:index, :new, :create]
  before_action :set_permit, only: [:show, :edit, :update, :destroy]

  # GET /regimes/:regime_id/permits
  # GET /regimes/:regime_id/permits.json
  def index
    @permits = permit_store.all
  end

  # GET /regimes/:regime_id/permits/1
  # GET /regimes/:regime_id/permits/1.json
  def show
  end

  # GET /regimes/:regimes_id/permits/new
  def new
    @permit = permit_store.build
  end

  # GET /regimes/:regimes_id/permits/1/edit
  def edit
  end

  # POST /regimes/:regimes_id/permits
  # POST /regimes/:regimes_id/permits.json
  def create
    @permit = permit_store.build(permit_params)

    respond_to do |format|
      if @permit.save
        format.html { redirect_to regime_permit_path(@regime, @permit), notice: 'Permit was successfully created.' }
        format.json { render :show, status: :created, location: regime_permit_path(@regime, @permit) }
      else
        format.html { render :new }
        format.json { render json: @permit.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /regimes/:regimes_id/permits/1
  # PATCH/PUT /regimes/:regimes_id/permits/1.json
  def update
    respond_to do |format|
      if @permit.update(permit_params)
        format.html { redirect_to regime_permit_path(@regime, @permit), notice: 'Permit was successfully updated.' }
        format.json { render :show, status: :ok, location: regime_permit_path(@regime, @permit) }
      else
        format.html { render :edit }
        format.json { render json: @permit.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /regimes/:regimes_id/permits/1
  # DELETE /regimes/:regimes_id/permits/1.json
  def destroy
    @permit.destroy
    respond_to do |format|
      format.html { redirect_to regime_permits_url, notice: 'Permit was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regime
      @regime = Regime.find_by!(slug: params[:regime_id])
    end

    def set_permit
      set_regime
      @permit = permit_store.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def permit_params
      params.require(:permit).
        permit(:permit_reference, :permit_category, :effective_date, :status)
    end

    def permit_store
      @permit_store ||= PermitStorageService.new(@regime)
    end
end
