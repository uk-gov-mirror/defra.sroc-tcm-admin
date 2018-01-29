module ApplicationHelper
  def active_for_current_controller(target_controller_name)
    if target_controller_name.include?(controller_name)
      "active"
    else
      ""
    end
  end

  def menu_path(regime, ctrl_name)
    url_for controller: ctrl_name, action: 'index', regime_id: regime.slug
  end

  def flash_class(level)
    case level
      when :notice then "alert-info"
      when :success then "alert-success"
      when :error then "alert-danger"
      when :alert then "alert-warning"
    end
  end

  def formatted_pence(value)
    number_to_currency(value / 100.0)
  end

  def formatted_date(date, include_time = false)
    fmt = "%d-%b-%Y"
    fmt = fmt + " %H:%M:%S" if include_time
    date.strftime(fmt)
  end

  def sortable(name)
    sorted = params[:sort] == name.to_s
    sort_dir = sorted ? params.fetch(:sort_direction, 'asc') : 'desc'
    options = {
      controller: controller_name,
      action: 'index',
      regime_id: @regime.slug,
      sort: name,
      sort_direction: switch_direction(sort_dir),
      page: 1,
      per_page: params[:per_page],
      search: params[:search]
    }
    if sorted
      span = "<span class='oi oi-caret-#{top_or_bottom(sort_dir)}'></span>"
    else
      span = ''
    end

    link_to(url_for(options)) do
      "#{th(name)} #{span}".html_safe
    end
  end

  def th(name)
    t(name, scope: 'table.heading')
  end

  def switch_direction(dir)
    if dir == 'desc'
      'asc'
    else
      'desc'
    end
  end

  def top_or_bottom(dir)
    dir == 'asc' ? 'top' : 'bottom'
  end
end
