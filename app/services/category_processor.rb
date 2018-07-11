# frozen_string_literal: true

class CategoryProcessor
  attr_reader :user, :regime

  def initialize(user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @user = user
  end

  def suggest_categories_for_file(header)
    @regime = header.regime
    permits = annual_billing_permit_groups(header)
  end

  def annual_billing_permits(header)
    counts = header.transaction_details.group(:reference_1).count
    counts.select do |k,v|
      header.transaction_details.where(reference_1: k).invoices.count == v
    end
  end
end
