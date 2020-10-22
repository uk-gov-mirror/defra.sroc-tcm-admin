# frozen_string_literal: true

class NextPasRetrospectiveReference < ServiceObject
  attr_accessor :reference

  def initialize(params = {})
    super()
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
  end

  def call
    n = SequenceCounter.next_invoice_number(@regime, @region)
    @reference = "PAS#{n.to_s.rjust(8, '0')}#{@region}"

    @result = true
    self
  end
end
