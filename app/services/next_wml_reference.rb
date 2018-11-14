class NextWmlReference < ServiceObject
  attr_accessor :reference

  def initialize(params = {})
    @regime = params.fetch(:regime)
    @region = params.fetch(:region)
  end

  def call
    n = SequenceCounter.next_invoice_number(@regime, @region)
    @reference = "#{@region}#{n.to_s.rjust(8, '0')}T"
    @result = true
    self
  end
end
