class PermitCategoriesController < AdminController
  include RegimeScope

  # GET /regime/cfd/permit_categories
  # GET /regime/cfd/permit_categories.json
  def index
    set_regime
    @permit_categories = @regime.permit_categories.order(:display_order, :code)
  end
end
