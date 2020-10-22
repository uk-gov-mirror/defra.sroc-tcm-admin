# frozen_string_literal: true

module Query
  class Users < QueryObject
    def initialize(opts = {})
      super()
      @regime = opts.fetch(:regime, "")
      @role = opts.fetch(:role, "")
      @sort_column = opts.fetch(:sort, :last_name)
      @sort_direction = opts.fetch(:sort_direction, "asc")
      @search = opts.fetch(:search, "")
    end

    def call
      q = User.all
      unless @regime.blank?
        r = Regime.find_by(slug: @regime)
        q = q.joins(:regime_users).merge(RegimeUser.enabled).merge(RegimeUser.where(regime_id: r.id)) if r
      end

      q = q.where(role: @role) unless @role.blank?
      q = q.search(@search) unless @search.blank?

      sort_users(q)
    end

    def sort_users(query)
      dir = @sort_direction
      case @sort_column.to_sym
      when :first_name
        query.order(first_name: dir, last_name: dir, id: dir)
      when :email
        query.order(email: dir, last_name: dir, id: dir)
      when :role
        query.order("CASE role " \
                "WHEN 1 THEN 0 " \
                "WHEN 0 THEN 1 " \
                "WHEN 3 THEN 2 " \
                "WHEN 2 THEN 3 " \
                "END #{dir}").order(last_name: dir, id: dir)
      when :enabled
        query.order(enabled: dir)
      else
        query.order(last_name: dir, first_name: dir, id: dir)
      end
    end
  end
end
