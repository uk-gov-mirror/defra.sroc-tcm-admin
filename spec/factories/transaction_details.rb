FactoryGirl.define do
  factory :transaction_detail do
    association :transaction_header
    sequence_number 1
    customer_reference "A12341234P"
    transaction_date { Time.zone.now }
    transaction_type "I"
    transaction_reference "A12345678"
    currency_code "GBP"
    line_amount "10099"
    line_area_code "10"
    line_description "Charges for something"
    line_income_stream_code "J"
    line_quantity "1"
    unit_of_measure "Each"
    unit_of_measure_price "10099"
  end
end
