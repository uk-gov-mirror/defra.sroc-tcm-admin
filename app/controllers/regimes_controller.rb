class RegimesController < ApplicationController
  before_action :set_regime, only: [:show, :edit, :update, :destroy]

  # GET /regimes
  # GET /regimes.json
  def index
    @regimes = Regime.all
  end

  # GET /regimes/1
  # GET /regimes/1.json
  def show
  end

  # GET /regimes/new
  def new
    @regime = Regime.new
  end

  # GET /regimes/1/edit
  def edit
  end

  # POST /regimes
  # POST /regimes.json
  def create
    @regime = Regime.new(regime_params)

    respond_to do |format|
      if @regime.save
        format.html { redirect_to @regime, notice: 'Regime was successfully created.' }
        format.json { render :show, status: :created, location: @regime }
      else
        format.html { render :new }
        format.json { render json: @regime.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /regimes/1
  # PATCH/PUT /regimes/1.json
  def update
    respond_to do |format|
      if @regime.update(regime_params)
        format.html { redirect_to @regime, notice: 'Regime was successfully updated.' }
        format.json { render :show, status: :ok, location: @regime }
      else
        format.html { render :edit }
        format.json { render json: @regime.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /regimes/1
  # DELETE /regimes/1.json
  def destroy
    @regime.destroy
    respond_to do |format|
      format.html { redirect_to regimes_url, notice: 'Regime was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regime
      @regime = Regime.find_by!(slug: params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def regime_params
      params.require(:regime).permit(:name)
    end
end
