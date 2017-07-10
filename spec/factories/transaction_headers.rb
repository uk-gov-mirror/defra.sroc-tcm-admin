FactoryGirl.define do
  factory :transaction_header do
    association :regime
    feeder_source_code "CFD"
    region "E"
    file_sequence_number 0
    bill_run_id "01234"
    generated_at { DateTime.now }

    trait :with_details do
      after(:create) do |instance|
        (1..3).each do |n|
          FactoryGirl.create(:transaction_detail, sequence_number: n, transaction_header_id: instance.id)
        end
      end
    end
  end
end
