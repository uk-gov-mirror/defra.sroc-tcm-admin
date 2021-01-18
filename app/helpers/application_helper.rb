# frozen_string_literal: true

module ApplicationHelper
  include FormattingUtils

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
    url_for controller: ctrl_name, action: "index", regime_id: regime.slug
  end

  def flash_class(level)
    levels = {
      notice: "alert-info",
      success: "alert-success",
      error: "alert-danger",
      alert: "alert-warning"
    }
    levels[level]
  end

  def sortable(name, view_model)
    sort_col = view_model.sort.to_sym
    sort_dir = view_model.sort_direction

    cls = "sort-link"
    if name.to_sym == sort_col
      span = "<span class='oi oi-caret-#{top_or_bottom(sort_dir)}'></span>"
      cls += " sorted sorted-#{sort_dir}"
    else
      span = ""
    end

    link_to("#", class: cls, data: { column: name }) do
      "#{th(name)} #{span}".html_safe
    end
  end

  def view_scope
    "table.heading.#{controller_name}"
  end

  def th(name)
    t(name, scope: view_scope)
  end

  def switch_direction(dir)
    if dir == "desc"
      "asc"
    else
      "desc"
    end
  end

  def top_or_bottom(dir)
    dir == "asc" ? "top" : "bottom"
  end

  def param_or_cookie(key, default_value = nil)
    v = params.fetch(key, nil)
    v = cookies.fetch(key, default_value) if v.blank?
    v
  end

  def current_git_commit
    @current_git_commit ||= begin
      sha =
        if Rails.env.production?
          capistrano_file = Rails.root.join "REVISION"

          File.open(capistrano_file, &:gets) if File.exist? capistrano_file
        else
          `git rev-parse HEAD`
        end

      sha[0...7] if sha.present?
    end
  end
end
