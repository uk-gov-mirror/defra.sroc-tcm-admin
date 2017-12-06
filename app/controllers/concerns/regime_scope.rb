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
    # FIXME: this is just to avoid not having a regime set on entry
    # this will be replaced by using user regimes roles/permissions
    if params.fetch(:regime_id, nil)
      @regime = Regime.find_by!(slug: params[:regime_id])
    else
      @regime = Regime.first
    end
  end
  # :nocov:
end
