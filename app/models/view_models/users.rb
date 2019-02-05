module ViewModels
  class Users
    include RegimeScope, ActionView::Helpers::FormOptionsHelper

    attr_accessor :regime, :role, :search, :sort,
      :sort_direction, :page, :per_page

    def initialize(params = {})
      @regime = params.fetch(:regime, "")
      @search = ""
      @role = ""
      @page = 1
      @per_page = 10
      @sort = 'last_name'
      @sort_direction = 'asc'
    end

    def users
      @users ||= fetch_check_users
    end

    def paged_users
      @paged_users ||= users.page(page).per(per_page)
    end

    def check_params
      @regime = '' if regime == 'all'
      @role = '' if role == 'all'
      @page = 1 if page.blank?
      @page = 1 unless page.to_i.positive?
      @per_page = 10 if per_page.blank?
      @per_page = 10 unless per_page.to_i.positive?
      # fetch transactions to validate/reset page
      users
    end

    def fetch_check_users
      t = fetch_users
      pg = page.to_i
      perp = per_page.to_i
      max_pages = (t.count / perp.to_f).ceil
      @page = 1 if pg > max_pages
      t
    end

    # override me for different views
    def fetch_users
      Query::Users.call(regime: regime,
                        role: role,
                        sort: sort,
                        sort_direction: sort_direction,
                        search: search)
    end
    
    def regime_options
      options_for_select([['All', '']] +
                         available_regimes.map { |r| [r.title, r.slug] },
                         regime)
    end

    def role_options
      options_for_select([['All', '']] +
                         available_roles.map { |r| [r[:name], r[:value]] },
                         role)
    end

    private

    def available_regimes
      @available_regimes ||= Regime.all.order(:title)
    end

    def available_roles
      @available_roles ||= User.ordered_roles.map do |r|
        { name: I18n.t(r, scope: 'user.roles'), value: User.roles[r] }
      end
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
