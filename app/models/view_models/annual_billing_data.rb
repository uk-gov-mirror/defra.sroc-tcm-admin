module ViewModels
  class AnnualBillingData
    attr_reader :regime, :upload, :user
    attr_accessor :sort, :sort_direction, :page, :per_page

    def initialize(params)
      @regime = params.fetch(:regime)
      @upload = params.fetch(:upload)
      @user = params.fetch(:user)
      @sort = 'line_number'
      @sort_direction = 'asc'
      @page = 1
      @per_page = 10
    end

    def errors
      @errors ||= sorted_paged_errors
    end
    
    private

    def sorted_paged_errors
      sorted_errors.page(page).per(per_page)
    end

    def sorted_errors
      upload.data_upload_errors.order(sort => sort_direction)
    end
  end
end
