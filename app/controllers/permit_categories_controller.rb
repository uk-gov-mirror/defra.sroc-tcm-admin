# frozen_string_literal: true

class PermitCategoriesController < AdminController
  include FinancialYear
  include RegimeScope
  before_action :set_regime, only: %i[index new create]
  before_action :set_permit_category, only: %i[show edit update destroy]

  # GET /regime/cfd/permit_categories
  # GET /regime/cfd/permit_categories.json
  def index
    set_regime
    set_financial_year
    q = params.fetch(:search, "")
    sort_col = params.fetch(:sort, :code)
    sort_dir = params.fetch(:sort_direction, "asc")
    pg = params.fetch(:page, 1)
    per_pg = params.fetch(:per_page, 10)
    # As long as the param is set we want to return `true`, else return `false`.
    # We have to pass a default return value to `fetch()` else it will return an
    # error. So the bang at the beginning reverses the `nil?` check at the end
    # which is how we get our true or false result
    #
    # unpaged not set = unpaged.nil? is true  = !true is false
    # unpaged is set  = unpaged.nil? is false = !false is true
    unpaged = !params.fetch(:unpaged, nil).nil?
    @financial_years = Query::PermitCategoryYears.call

    @categories = Query::PermitCategories.call(regime: @regime,
                                               financial_year: @financial_year,
                                               search: q,
                                               sort: sort_col,
                                               sort_direction: sort_dir)

    respond_to do |format|
      format.html do
        @view_model = ViewModels::PermitCategories.new
        @view_model.assign_attributes(
          permit_categories: @categories.page(pg).per(per_pg),
          financial_year: @financial_year,
          search: q,
          sort: sort_col,
          sort_direction: sort_dir,
          page: pg,
          per_page: per_pg,
          financial_years: @financial_years
        )

        if request.xhr?
          render partial: "table", locals: { view_model: @view_model }
        else
          render
        end
      end
      format.json do
        cats = permit_store.search_all(@financial_year, q,
                                       sort_col, sort_dir)
        cats = cats.page(pg).per(per_pg) unless unpaged

        @permit_categories = if unpaged
                               present_categories_unpaged(cats)
                             else
                               present_categories(cats)
                             end

        render json: @permit_categories
      end
    end
  end

  def show; end

  def new
    set_financial_year
    @permit_category = @regime.permit_categories
                              .build(valid_from: @financial_year,
                                     status: "active")
  end

  def edit
    # NOTE: this might not be the actual one we want to edit, it might
    # just the the category that is in use for our given financial year
    # The #update method will have to decide whether to create a new
    # record or modify this one
    set_financial_year
    @permit_category = @regime.permit_categories.find(params[:id])
    @timeline = permit_store.permit_category_versions(@permit_category.code)
  end

  def create
    set_financial_year
    p = permit_category_params
    result = CreatePermitCategory.call(regime: @regime,
                                       valid_from: @financial_year,
                                       user: current_user,
                                       code: p[:code],
                                       description: p[:description])

    @permit_category = result.permit_category

    respond_to do |format|
      if result.success?
        format.html do
          redirect_to regime_permit_categories_path(@regime,
                                                    fy: @financial_year),
                      notice: "Permit category was successfully created."
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

    case params[:commit]
    when "Remove Category"
      if can_remove_permit_category?(cat.code, @financial_year)
        @permit_category = permit_store
                           .update_or_create_new_version(
                             cat.code, permit_category_params[:description],
                             @financial_year, "excluded"
                           )
      else
        @permit_category.errors.add(:base, "^This code is in use and cannot be removed")
      end
    when "Reinstate Category"
      @permit_category = permit_store.update_or_create_new_version(
        cat.code, permit_category_params[:description],
        @financial_year,
        "active"
      )
    else
      @permit_category = permit_store
                         .update_or_create_new_version(
                           cat.code, permit_category_params[:description],
                           @financial_year, cat.status
                         )
    end
    result = @permit_category.errors.empty?

    respond_to do |format|
      if result
        format.html do
          redirect_to(
            regime_permit_categories_path(@regime, fy: @financial_year),
            notice: "Permit category was successfully updated."
          )
        end
        format.json { render :show, status: :ok, location: regime_permit_category_path(@regime, @permit_category) }
      else
        @timeline = permit_store.permit_category_versions(@permit_category.code)
        format.html { render :edit }
        format.json { render json: @permit_category.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # update record status or create new 'excluded' record
    @permit_category.destroy
    respond_to do |format|
      format.html do
        redirect_to regime_permit_categories_url(@regime), notice: "Permit category was successfully destroyed."
      end
      format.json { head :no_content }
    end
  end

  private

  def set_permit_category
    set_regime
    set_financial_year
    @permit_category = @regime.permit_categories.find(params[:id])
  end

  def set_financial_year
    @financial_year = params.fetch(:fy, "1819")
    @financial_year = "1819" unless valid_financial_year? @financial_year
  end

  def permit_category_params
    params.require(:permit_category).permit(:code, :description, :status,
                                            :valid_from, :valid_to)
  end

  def can_remove_permit_category?(code, financial_year)
    # check that no transactions for the given financial year
    # have used this code
    @regime
      .transaction_details
      .financial_year(financial_year)
      .where(category: code)
      .count
      .zero?
  end

  def present_categories_unpaged(categories)
    {
      permit_categories: PermitCategoriesPresenter.wrap(categories)
    }
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
