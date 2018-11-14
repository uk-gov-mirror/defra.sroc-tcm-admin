class PermitCategoryPresenter < SimpleDelegator
  def self.wrap(collection)
    collection.map { |o| new o }
  end

  def as_json(options = {})
     path = Rails.application.routes.url_helpers.
       edit_regime_permit_category_path(regime, self)
    {
      id: id,
      code: code,
      description: description,
      valid_from: valid_from,
      valid_to: valid_to,
      status: status,
      edit_link: path
    }
  end

protected
  def permit_category
    __getobj__
  end
end
