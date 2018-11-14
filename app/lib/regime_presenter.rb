module RegimePresenter
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
end
