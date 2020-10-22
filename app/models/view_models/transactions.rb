# frozen_string_literal: true

module ViewModels
  class Transactions
    include ActionView::Helpers::FormOptionsHelper
    include RegimeScope

    attr_reader :regime, :user, :permit_all_regions
    attr_writer :financial_year
    attr_accessor :search, :sort, :sort_direction,
                  :page, :per_page, :unapproved

    def initialize(params = {})
      @regime = params.fetch(:regime)
      @user = params.fetch(:user)
      @page = 1
      @per_page = 10
      @sort = "customer_reference"
      @sort_direction = "asc"
      @permit_all_regions = false
      @unapproved = false
    end

    def region=(val)
      @region = if val.blank? || val == "all"
                  if permit_all_regions
                    "all"
                  else
                    available_regions.first
                  end
                elsif available_regions.include?(val)
                  val
                else
                  available_regions.first
                end
    end

    def region
      if permit_all_regions && @region == "all"
        @region
      elsif available_regions.include?(@region)
        @region
      else
        @region = available_regions.first
      end
    end

    def financial_year
      if available_years.include? @financial_year
        @financial_year
      else
        ""
      end
    end

    def transactions
      @transactions ||= fetch_check_transactions
    end

    def paged_transactions
      @paged_transactions ||= transactions.page(page).per(per_page)
    end

    def check_params
      @page = 1 if page.blank?
      @page = 1 unless page.to_i.positive?
      @per_page = 10 if per_page.blank?
      @per_page = 10 unless per_page.to_i.positive?
      @unapproved = ActiveModel::Type::Boolean.new.cast(@unapproved)
      # fetch transactions to validate/reset page
      transactions
    end

    def fetch_check_transactions
      t = fetch_transactions
      pg = page.to_i
      perp = per_page.to_i
      max_pages = (t.count / perp.to_f).ceil
      @page = 1 if pg > max_pages
      t
    end

    # override me for different views
    def fetch_transactions
      Query::TransactionsToBeBilled.call(regime: regime,
                                         region: region,
                                         unapproved: unapproved,
                                         sort: sort,
                                         sort_direction: sort_direction,
                                         financial_year: financial_year,
                                         search: search)
    end

    # override me for different views
    def csv_transactions(limit = 15_000)
      @csv_transactions ||= presenter.wrap(transactions.unexcluded.limit(limit), user)
    end

    def present_paged_transactions
      @present_paged_transactions ||= page_and_present_transactions
    end

    # override me if 'all' regions is permitted in the view
    def region_options
      options_for_select(available_regions.map { |r| [r, r] }, region)
    end

    def all_region_options
      opts = available_regions.length == 1 ? [] : [%w[All all]]
      options_for_select(opts + available_regions.map { |r| [r, r] }, region)
    end

    def financial_year_options
      opts = available_years.length == 1 ? [] : [%w[All all]]
      options_for_select(opts + pretty_years_list, financial_year)
    end

    def table_partial_name
      "#{regime.slug}_table"
    end

    def permit_category_timestamp
      @permit_category_timestamp ||= Query::PermitCategoryLastChanged.call(
        regime: regime
      )
    end

    private

    def pretty_years_list
      available_years.sort.map { |y| ["#{y[0..1]}/#{y[2..3]}", y] }
    end

    def available_regions
      @available_regions ||= Query::Regions.call(regime: regime)
    end

    def available_years
      @available_years ||= Query::FinancialYears.call(regime: regime)
    end

    def page_and_present_transactions
      pt = paged_transactions
      Kaminari.paginate_array(presenter.wrap(pt, user),
                              total_count: pt.total_count,
                              limit: pt.limit_value,
                              offset: pt.offset_value)
    end
  end
end
