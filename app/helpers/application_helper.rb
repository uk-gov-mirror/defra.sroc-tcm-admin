module ApplicationHelper
  def active_for_current_controller(target_controller_name)
    if target_controller_name == controller_name
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
end
