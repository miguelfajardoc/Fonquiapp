FactoryBot.define do
  factory :client do
    association :zone
    sequence(:name) { |n| "#{Faker::Company.name} #{n}" }
    address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.phone_number }
  end
end
