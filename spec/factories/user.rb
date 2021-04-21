# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    email { "system@example.com" }
    first_name { "System" }
    last_name { "Account" }
    role { "admin" }
    password { "Secret123" }
  end
end
