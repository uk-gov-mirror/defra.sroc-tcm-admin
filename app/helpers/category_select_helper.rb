# frozen_string_literal: true

module CategorySelectHelper
  def category_select_tag(transaction)
    render partial: "shared/category_select", locals: { transaction: transaction }
  end
end
