class PermitCategoriesController < AdminController
  include RegimeScope, FinancialYear
  before_action :set_regime, only: [:index, :new, :create]
  before_action :set_permit_category, only: [:show, :edit, :update, :destroy]

  # GET /regime/cfd/permit_categories
  # GET /regime/cfd/permit_categories.json
  def index
    set_regime
    set_financial_year
    q = params.fetch(:search, "")
    sort_col = params.fetch(:sort, :code)
    sort_dir = params.fetch(:sort_direction, 'asc')
    pg = params.fetch(:page, 1)
    per_pg = params.fetch(:per_page, 10)
    # fy = params.fetch(:fy, '1819')

    respond_to do |format|
      format.html
      format.json do
        # cats = permit_store.all_for_financial_year(fy).
        #   order("string_to_array(code, '.')::int[]").
        cats = permit_store.search_all(@financial_year, q,
                                       sort_col, sort_dir).
                                       page(pg).per(per_pg)
        @permit_categories = present_categories(cats)
        render json: @permit_categories
      end
    end
  end

  def show
  end

  def new
    set_financial_year
    @permit_category = @regime.permit_categories.
      build(valid_from: @financial_year,
            status: 'active')
  end

  def edit
    # NOTE: this might not be the actual one we want to edit, it might
    # just the the category that is in use for our given financial year
    # The #update method will have to decide whether to create a new
    # record or modify this one
    @permit_category = @regime.permit_categories.find(params[:id])
  end

  def create
    set_financial_year
    p = permit_category_params
    @permit_category = permit_store.new_permit_category(p[:code],
                                                        p[:description],
                                                        @financial_year)

    respond_to do |format|
      if @permit_category.valid?
        format.html do
          redirect_to regime_permit_categories_path(@regime,
                                                   fy: @financial_year),
                                                   notice: 'Permit category was successfully created.'
        end
        format.json { render :show, status: :created, location: regime_permit_category_path(@regime, @permit_category) }
      else
        format.html { render :new }
        format.json { render json: @permit_category.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    # NOTE: the submitted record might not be the one we actually want
    # to update
    result = true
    cat = @permit_category
    status = cat.status

    if params[:commit] == 'Remove Category'
      if can_remove_permit_category?(cat.code, @financial_year)
        @permit_category = permit_store.
          update_or_create_new_version(
            cat.code, permit_category_params[:description],
            @financial_year, 'excluded')
      else
       @permit_category.errors.add(base: "^This code is in use and cannot be removed")
       result = false 
      end
    elsif params[:commit] == 'Reinstate Category'
      @permit_category = permit_store.update_or_create_new_version(
        cat.code, permit_category_params[:description],
        @financial_year,
        'active')
    else
      @permit_category = permit_store.
        update_or_create_new_version(
          cat.code, permit_category_params[:description],
          @financial_year, cat.status)
    end
    # result = false
    # create = false
    # if @permit_category.valid_from != @financial_year
    #   # we need to create a new permit_category to represent the change
    #   create = true
    #   parms = permit_category_params
    #
    #   @permit_category = permit_store.build_permit_category(
    #     parms[:code],
    #     parms[:description],
    #     @financial_year,
    #     'active')
    #   result = @permit_category.save
    # else
    #   result = @permit_category.update(permit_category_params)
    # end

    respond_to do |format|
      if result
        format.html { redirect_to regime_permit_categories_path(@regime, fy: @financial_year), notice: 'Permit category was successfully updated.' }
        format.json { render :show, status: :ok, location: regime_permit_category_path(@regime, @permit_category) }
      else
        format.html { render :edit }
        format.json { render json: @permit_category.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # update record status or create new 'excluded' record
    @permit_category.destroy
    respond_to do |format|
      format.html { redirect_to regime_permit_categories_url(@regime), notice: 'Permit category was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_permit_category
    set_regime
    set_financial_year
    @permit_category = @regime.permit_categories.find(params[:id])
    # cat = @regime.permit_categories.find(params[:id])
    # @permit_category = if cat.valid_from == @financial_year
    #                      # editing the actual one we want
    #                      cat
    #                    else
    #                      # want to edit category for a financial year
    #                      # that is not the valid_from so effectively we
    #                      # need to introduce a new permit_category record
    #                      # for the requested financial year
    #                      @regime.permit_categories.build(code: cat.code,
    #                                                      description: cat.description,
    #                                                      status: cat.status,
    #                                                      valid_from: @financial_year)
    #                    end
  end

  def set_financial_year
    @financial_year = params.fetch(:fy, '1819')
    @financial_year = '1819' unless valid_financial_year? @financial_year
  end

  def permit_category_params
    params.require(:permit_category).permit(:code, :description, :status,
                                           :valid_from, :valid_to)
  end

  def can_remove_permit_category?(code, financial_year)
    # check that no transactions for the given financial year
    # have used this code
    @regime.transaction_details.financial_year(financial_year).
      where(category: code).count.zero?
  end

  def present_categories(categories)
    arr = Kaminari.paginate_array(PermitCategoryPresenter.wrap(categories),
                                  total_count: categories.total_count,
                                  limit: categories.limit_value,
                                  offset: categories.offset_value)
    {
      pagination: {
        current_page: arr.current_page,
        prev_page: arr.prev_page,
        next_page: arr.next_page,
        per_page: arr.limit_value,
        total_pages: arr.total_pages,
        total_count: arr.total_count
      },
      permit_categories: arr
    }
  end

  def permit_store
    @permit_store ||= PermitStorageService.new(@regime, current_user)
  end
end
