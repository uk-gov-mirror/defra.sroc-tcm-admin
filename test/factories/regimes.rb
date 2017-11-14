FactoryBot.define do
  factory :regime, aliases: [:pas] do
    name "PAS"
    title "Installations"

    factory :cfd do
      name "CFD"
      title "Water Quality"
    end

    factory :wabs do
      name "WABS"
      title "Waste"
    end
  end
end
