FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "Product #{n}" }
    price { Faker::Commerce.price(range: 1.0..999.0) }
  end
end
