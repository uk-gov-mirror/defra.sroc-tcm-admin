class ServiceObject
  def self.call(parms = {})
    new(parms).call
  end

  # def call(params)

  def success?
    @result
  end

  def failed?
    !@result
  end

  def str_to_bool(val)
    ActiveModel::Type::Boolean.new.cast(val.to_s)
  end
end
