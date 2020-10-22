# frozen_string_literal: true

class PermitCategoriesLookupController < ApplicationController
  include RegimeScope
  before_action :set_regime, only: [:index]

  # GET /regime/cfd/permit_categories_lookup.json
  def index
    financial_year = params.fetch(:fy)
    q = params.fetch(:q, "")

    categories = Query::PermitCategoryLookup.call(regime: @regime,
                                                  financial_year: financial_year,
                                                  query: q)

    respond_to do |format|
      format.json do
        render json: present(categories)
      end
    end
  end

  private

  def present(categories)
    categories.map { |c| { code: c.code, description: c.description } }
  end
end
