class PermitCategoriesController < AdminController
  include RegimeScope
  before_action :set_regime, only: [:index, :new, :create]
  before_action :set_permit_category, only: [:show, :edit, :update, :destroy]

  # GET /regime/cfd/permit_categories
  # GET /regime/cfd/permit_categories.json
  def index
    @permit_categories = @regime.permit_categories.order(:display_order, :code)
  end

  # GET /regime/cfd/permit_categories/1
  # GET /regime/cfd/permit_categories/1.json
  def show
  end

  # GET /regime/cfd/permit_categories/new
  def new
    @permit_category = @regime.permit_categories.build
  end

  # GET /regime/cfd/permit_categories/1/edit
  def edit
  end

  # POST /regime/cfd/permit_categories
  # POST /regime/cfd/permit_categories.json
  def create
    @permit_category = @regime.permit_categories.build(permit_category_params)

    respond_to do |format|
      if @permit_category.save
        format.html { redirect_to regime_permit_category_path(@regime, @permit_category), notice: 'Permit category was successfully created.' }
        format.json { render :show, status: :created, location: regime_permit_category_path(@regime, @permit_category) }
      else
        format.html { render :new }
        format.json { render json: @permit_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /regime/cfd/permit_categories/1
  # PATCH/PUT /regime/cfd/permit_categories/1.json
  def update
    respond_to do |format|
      if @permit_category.update(permit_category_params)
        format.html { redirect_to regime_permit_category_path(@regime, @permit_category), notice: 'Permit category was successfully updated.' }
        format.json { render :show, status: :ok, location: regime_permit_category_path(@regime, @permit_category) }
      else
        format.html { render :edit }
        format.json { render json: @permit_category.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /regime/cfd/permit_categories/1
  # DELETE /regime/cfd/permit_categories/1.json
  def destroy
    @permit_category.destroy
    respond_to do |format|
      format.html { redirect_to regime_permit_categories_url(@regime), notice: 'Permit category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    def set_permit_category
      set_regime
      @permit_category = @regime.permit_categories.find(params[:id])
    end

    def permit_category_params
      params.require(:permit_category).permit(:regime, :code, :description, :status, :display_order)
    end
end
