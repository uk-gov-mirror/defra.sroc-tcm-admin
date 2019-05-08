module ViewModels
  class ImportedTransactionFiles
    include RegimeScope, ActionView::Helpers::FormOptionsHelper

    attr_reader :regime, :user, :permit_all_regions
    attr_accessor :region, :status, :search, :sort, :sort_direction,
      :page, :per_page

    def initialize(params = {})
      @regime = params.fetch(:regime)
      @user = params.fetch(:user)
      @status = params.fetch(:status, '')
      @page = 1
      @per_page = 10
      @sort = 'created_at'
      @sort_direction = 'desc'
      @permit_all_regions = true
    end

    def region=(val)
      if val.blank? || val == 'all'
        if permit_all_regions
          @region = ''
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
      if permit_all_regions && @region.blank?
        @region
      else
        if available_regions.include?(@region)
          @region
        else
          @region = available_regions.first
        end
      end
    end

    def imported_files
      @imported_files ||= fetch_check_imported_files
    end

    def paged_imported_files
      @paged_imported_files ||= imported_files.page(page).per(per_page)
    end

    def check_params
      @page = 1 if page.blank?
      @page = 1 unless page.to_i.positive?
      @per_page = 10 if per_page.blank?
      @per_page = 10 unless per_page.to_i.positive?
      # fetch transactions to validate/reset page
      imported_files
    end

    def fetch_check_imported_files
      t = fetch_imported_files
      pg = page.to_i
      perp = per_page.to_i
      max_pages = (t.count / perp.to_f).ceil
      @page = 1 if pg > max_pages
      t
    end

    # override me for different views
    def fetch_imported_files
      Query::ImportedTransactionFiles.call(regime: regime,
                                           region: region,
                                           status: status,
                                           sort: sort,
                                           sort_direction: sort_direction,
                                           search: search)
    end
    
    # override me if 'all' regions is permitted in the view
    def region_options
      all_region_options
      # options_for_select(available_regions.map { |r| [r, r] }, region)
    end

    def all_region_options
      opts = available_regions.length == 1 ? [] : [['All', '']]
      options_for_select(opts + available_regions.map { |r| [r, r] }, region)
    end

    def status_options
      options_for_select([
        [ 'All', ''], ['Active', 'included'], ['Removed', 'removed']
      ], status)
    end

    private

    def available_regions
      @available_regions ||= Query::TransactionFileRegions.call(regime: regime)
    end
  end
end
