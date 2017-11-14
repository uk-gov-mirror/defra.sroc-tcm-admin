FactoryBot.define do
  factory :permit_category do
    regime
    code "2.3.4"
    description "Sewage 50,000 - 150,000 m3/day"
    status "active"
    display_order 1

    factory :permit_category_pas do
      code "2.4.4"
      description "Section 4.1 Organic; Organic other"
    end

    factory :permit_category_wabs do
      code "2.15.2"
      description "Bespoke Deployment"
    end
  end
end
