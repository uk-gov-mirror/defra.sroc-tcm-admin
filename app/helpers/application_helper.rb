module ApplicationHelper
  def yn_flag(bool)
    bool ? 'Y' : 'N'
  end

  def tcm_form_with(*args, &block)
    options = args.extract_options!

    content_tag(:div,
                form_with(*(args << options.merge(builder: TcmFormBuilder)),
                         &block),
                         class: "tcm_form")
  end

  def make_page_title(title)
    "#{title} - Tactical Charging Module - DEFRA"
  end

  def active_for_current_controller(target_controller_name)
    if target_controller_name.include?(controller_name)
      "active"
    else
      ""
    end
  end

  def menu_path(regime, ctrl_name)
    # ctrl_name = 'transactions' if ctrl_name == 'transaction_audits'
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

  def formatted_pence_without_symbol(value)
    number_to_currency(value / 100.0, format: "%n") unless value.blank?
  end

  def slash_formatted_date(date)
    date.strftime("%d/%m/%y")
  end

  def formatted_date(date, include_time = false)
    fmt = "%d-%b-%Y"
    fmt = fmt + " %H:%M:%S" if include_time
    date.strftime(fmt)
  end

  def sortable(name, view_model)
    sort_col = view_model.sort.to_sym
    sort_dir = view_model.sort_direction

    cls = 'sort-link'
    if name.to_sym == sort_col
      span = "<span class='oi oi-caret-#{top_or_bottom(sort_dir)}'></span>"
      cls = cls + " sorted sorted-#{sort_dir}"
    else
      span = ''
    end

    link_to('#', class: cls, data: { column: name }) do
      "#{th(name)} #{span}".html_safe
    end
  end

  # def sortable(name, default_col = 'customer_reference')
  #   sorted = params.fetch(:sort, default_col) == name.to_s
  #   sort_dir = sorted ? params.fetch(:sort_direction, 'asc') : 'desc'
  #   # options = {
  #   #   controller: controller_name,
  #   #   action: 'index',
  #   #   regime_id: @regime.slug,
  #   #   sort: name,
  #   #   sort_direction: switch_direction(sort_dir),
  #   #   page: 1,
  #   #   per_page: params[:per_page],
  #   #   search: params[:search]
  #   # }
  #   cls = "sort-link"
  #   if sorted
  #     span = "<span class='oi oi-caret-#{top_or_bottom(sort_dir)}'></span>"
  #     cls = cls + " sorted sorted-#{sort_dir}"
  #   else
  #     span = ''
  #   end
  #
  #   # link_to(url_for(options)) do
  #   link_to('#', class: cls, data: { column: name }) do
  #     "#{th(name)} #{span}".html_safe
  #   end
  # end

  def view_scope
    "table.heading.#{controller_name}"
  end

  def th(name)
    t(name, scope: view_scope)
    # t(name, scope: 'table.heading')
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

  def param_or_cookie(key, default_value = nil)
    v = params.fetch(key, nil)
    v = cookies.fetch(key, default_value) if v.blank?
    v
  end

  def app_version_info
    if File.exist? Rails.root.join("APPVERSION")
      File.read(Rails.root.join("APPVERSION")).chomp
    elsif File.exist? Rails.root.join("REVISION")
      File.read(Rails.root.join("REVISION")).chomp
    end
  rescue => e
    TcmLogger.notify(e)
  end
end
