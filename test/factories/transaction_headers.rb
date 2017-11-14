FactoryBot.define do
  factory :transaction_header do
    regime
    feeder_source_code "PAS"
    region "E"
    file_sequence_number 123
    bill_run_id "01234"
    generated_at { DateTime.now }

    trait :with_details do
      after(:create) do |instance|
        (1..3).each do |n|
          FactoryBot.create(:transaction_detail, sequence_number: n, transaction_header_id: instance.id)
        end
      end
    end
  end

  factory :cfd_transaction_header, class: TransactionHeader do
    feeder_source_code "CFD"
    region "A"
    file_sequence_number 371
    bill_run_id ""
    generated_at "Tue 29 Aug 2017 000000 UTC +0000"
    transaction_count 61
    invoice_total 0
    credit_total -279042
  end
end
