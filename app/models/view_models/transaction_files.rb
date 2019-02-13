module ViewModels
  class TransactionFiles
    include RegimeScope, ActionView::Helpers::FormOptionsHelper

    attr_reader :regime, :user, :permit_all_regions
    attr_accessor :region, :prepost, :search, :sort, :sort_direction,
      :page, :per_page

    def initialize(params = {})
      @regime = params.fetch(:regime)
      @user = params.fetch(:user)
      @prepost = params.fetch(:prepost, '')
      @page = 1
      @per_page = 10
      @sort = 'file_reference'
      @sort_direction = 'asc'
      @permit_all_regions = false
    end

    def region=(val)
      if val.blank? || val == 'all'
        if permit_all_regions
          @region = 'all'
        else
          @region = available_regions.first
        end
      else
        if available_regions.include?(val)
          @region = val
        else
          @region = available_regions.first
        end
      end
      @region
    end

    def region
      if permit_all_regions && @region == 'all'
        @region
      else
        if available_regions.include?(@region)
          @region
        else
          @region = available_regions.first
        end
      end
    end

    def transaction_files
      @transaction_files ||= fetch_check_transaction_files
    end

    def paged_transaction_files
      @paged_transaction_files ||= transaction_files.page(page).per(per_page)
    end

    def check_params
      @page = 1 if page.blank?
      @page = 1 unless page.to_i.positive?
      @per_page = 10 if per_page.blank?
      @per_page = 10 unless per_page.to_i.positive?
      # fetch transactions to validate/reset page
      transaction_files
    end

    def fetch_check_transaction_files
      t = fetch_transaction_files
      pg = page.to_i
      perp = per_page.to_i
      max_pages = (t.count / perp.to_f).ceil
      @page = 1 if pg > max_pages
      t
    end

    # override me for different views
    def fetch_transaction_files
      Query::TransactionFiles.call(regime: regime,
                                   region: region,
                                   prepost: prepost,
                                   sort: sort,
                                   sort_direction: sort_direction,
                                   search: search)
    end
    
    # override me if 'all' regions is permitted in the view
    def region_options
      options_for_select(available_regions.map { |r| [r, r] }, region)
    end

    def all_region_options
      opts = available_regions.length == 1 ? [] : [['All', 'all']]
      options_for_select(opts + available_regions.map { |r| [r, r] }, region)
    end

    def prepost_options
      options_for_select([
        [ 'All', ''], ['Post', 'post'], ['Pre', 'pre']
      ], prepost)
    end

    private

    def available_regions
      @available_regions ||= Query::Regions.call(regime: regime)
    end
  end
end
