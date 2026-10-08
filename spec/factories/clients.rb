FactoryBot.define do
  factory :client do
    association :zone
    name { Faker::Company.name }
    address { Faker::Address.full_address }
    phone { Faker::PhoneNumber.phone_number }
  end
end
