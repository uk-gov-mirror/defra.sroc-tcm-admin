module Query
  class Users < QueryObject
    def initialize(opts = {})
      @regime = opts.fetch(:regime, '')
      @role = opts.fetch(:role, '')
      @sort_column = opts.fetch(:sort, :last_name)
      @sort_direction = opts.fetch(:sort_direction, 'asc')
      @search = opts.fetch(:search, '')
    end

    def call
      q = User.all
      unless @regime.blank?
        r = Regime.find_by(slug: @regime)
        if r
          q = q.joins(:regime_users).
            merge(RegimeUser.enabled).
            merge(RegimeUser.where(regime_id: r.id))
        end
      end
      
      q = q.where(role: @role) unless @role.blank?
      q = q.search(@search) unless @search.blank?
      
      sort_users(q)
    end

    def sort_users(q)
      dir = @sort_direction
      case @sort_column.to_sym
      when :first_name
        q.order(first_name: dir, last_name: dir, id: dir)
      when :email
        q.order(email: dir, last_name: dir, id: dir)
      when :role
        q.order("CASE role " \
                "WHEN 1 THEN 0 " \
                "WHEN 0 THEN 1 " \
                "WHEN 3 THEN 2 " \
                "WHEN 2 THEN 3 " \
                "END #{dir}").order(last_name: dir, id: dir)
      when :enabled
        q.order(enabled: dir)
      else
        q.order(last_name: dir, first_name: dir, id: dir)
      end
    end
  end
end
