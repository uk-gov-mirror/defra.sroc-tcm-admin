FactoryBot.define do
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
  factory :cfd_transaction_detail, class: TransactionDetail do
    sequence_number 1
    customer_reference "A60425822C"
    transaction_date "Tue 29 Aug 2017 000000 UTC +0000"
    transaction_type "C"
    transaction_reference "826951A"
    related_reference ""
    currency_code "GBP"
    header_narrative ""
    header_attr_1 "29-AUG-2017"
    header_attr_2 ""
    header_attr_3 ""
    header_attr_4 ""
    header_attr_5 ""
    header_attr_6 ""
    header_attr_7 ""
    header_attr_8 ""
    header_attr_9 ""
    header_attr_10 ""
    line_amount 23747
    line_vat_code ""
    line_area_code "3"
    line_description "Consent No - ANNNF/1751/1/1"
    line_income_stream_code "C"
    line_context_code "D"
    line_attr_1 "Green Rd. Pig Disposal"
    line_attr_2 "STORM SEWAGE OVERFLOW"
    line_attr_3 "01/04/17 - 10/08/17"
    line_attr_4 "365/132"
    line_attr_5 "C 1"
    line_attr_6 "E 1"
    line_attr_7 "S 1"
    line_attr_8 "684"
    line_attr_9 "96%"
    line_attr_10 ""
    line_attr_11 ""
    line_attr_12 ""
    line_attr_13 ""
    line_attr_14 ""
    line_attr_15 ""
    line_quantity 1
    unit_of_measure "Each"
    unit_of_measure_price 23747
    status "unbilled"
    filename nil
    reference_1 "ANNNF/1751"
    reference_2 "1"
    reference_3 "1"
    generated_filename nil
    generated_file_at nil
    temporary_cessation false
    temporary_cessation_start nil
    temporary_cessation_end nil
    category nil
    charge_calculation nil
    period_start "Sat 01 Apr 2017 000000 UTC +0000"
    period_end "Thu 10 Aug 2017 000000 UTC +0000"
  end
end
