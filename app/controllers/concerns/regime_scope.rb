module RegimeScope
  extend ActiveSupport::Concern

  # :nocov:
  def presenter
    name = "#{@regime.slug}_transaction_detail_presenter".camelize
    str_to_class(name) || TransactionDetailPresenter
  end

  def str_to_class(name)
    begin
      name.constantize
    rescue NameError => e
      nil
    end
  end

  def set_regime
    last_id = cookies[:regime_id]
    r_id = params.fetch(:regime_id, nil)

    # if last_id && r_id != last_id
    #   # switch regime - clear cookies
    #   cookies.delete(:regime_id)
    #   cookies.delete(:region)
    #   cookies.delete(:search)
    #   cookies.delete(:sort)
    #   cookies.delete(:sort_direction)
    #   cookies.delete(:page)
    #   cookies.delete(:per_page)
    # end

    if r_id
      @regime = current_user.set_selected_regime(r_id)
      redirect_to root_path unless @regime.to_param == r_id
    else
      @regime = current_user.selected_regime
    end
    cookies[:regime_id] = @regime.to_param unless @regime.nil?
  end
  # :nocov:
end
