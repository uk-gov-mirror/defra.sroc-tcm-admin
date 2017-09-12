# frozen_string_literal: true

class PermitStorageService
  attr_reader :user, :regime

  def initialize(regime, user = nil)
    # when instantiated from a controller the 'current_user' should
    # be passed in. This will allow us to audit actions etc. down the line.
    @regime = regime
    @user = user
  end

  def find(id)
    regime.permits.find(id)
  end

  def all
    regime.permits.all
  end

  def build(permit_attrs = {})
    regime.permits.build(permit_attrs)
  end

  # def create(permit_attrs, callbacks = {})
  #   permit = regime.permits.create(permit_attrs)
  #   if permit.save
  #     callbacks.fetch(:success).call(permit) if callbacks.has_key? :success
  #   else
  #     callbacks.fetch(:failure).call(permit) if callbacks.has_key? :failure
  #   end
  #   permit
  # end

end

