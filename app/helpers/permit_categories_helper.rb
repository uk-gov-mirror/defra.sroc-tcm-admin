module PermitCategoriesHelper
  def pretty_financial_year(fy)
    (fy[0..1] + '/' + fy[2..3]) unless fy.blank?
  end
end
