FactoryBot.define do
  factory :client do
    association :zone
    name { Faker::Company.name }
    address { Faker::Address.full_address }
    url { Faker::Internet.url }
    phone { Faker::PhoneNumber.phone_number }
  end
end
