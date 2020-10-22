# frozen_string_literal: true

module RegimePresenter
  def presenter
    name = "#{@regime.slug}_transaction_detail_presenter".camelize
    str_to_class(name) || TransactionDetailPresenter
  end

  def str_to_class(name)
    name.constantize
  rescue NameError
    nil
  end
end
