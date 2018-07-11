require 'test_helper.rb'

class CategoryProcessorTest < ActiveSupport::TestCase
  def setup
    @header = transaction_headers(:cfd_annual)
    fixup_transactions(@header)
 
    @processor = CategoryProcessor.new(@header.regime)
  end

  def test_annual_billing_permit_groups_returns_all_invoice_transactions
    permits = @processor.annual_billing_permits(@header)
    assert_equal 7, permits.count
    assert_not_includes permits.keys, 'AAAF/2/3'
  end


  def fixup_transactions(header)
    t = transaction_details(:cfd_annual)
    [
      ["AAAA", "1", "1", 12345, "A1234"],
      ["AAAB", "1", "1", 67890, "A3453"],
      ["AAAC", "1", "1", 12233, "A9483"],
      ["AAAD", "1", "1", 22991, "A33133"],
      ["AAAE", "1", "1", 435564, "A938392"],
      ["AAAE", "1", "2", 23665, "A938392"],
      ["AAAF", "2", "3", 124322, "A993022"],
      ["AAAF", "2", "3", -123991, "A993022"]
    ].each_with_index do |ref, i|
      tt = t.dup
      tt.sequence_number = 2 + i
      tt.reference_1 = ref[0..2].join('/')
      tt.reference_2 = ref[1]
      tt.reference_3 = ref[2]
      tt.line_amount = ref[3]
      tt.customer_reference = ref[4]
      tt.transaction_header_id = header.id
      tt.save!
    end
  end
end
