# frozen_string_literal: true

class NextCfdRetrospectiveReference < ServiceObject
  attr_accessor :reference

  def initialize(params = {})
    super()
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
  end

  def call
    n = SequenceCounter.next_invoice_number(@regime, @region)
    @reference = "#{n.to_s.rjust(5, '0')}2#{@region}"
    @result = true
    self
  end
end
