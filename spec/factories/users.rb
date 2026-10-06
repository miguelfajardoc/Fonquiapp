FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "usuario#{n}@example.com" }
    password { "123456" }
  end
end
