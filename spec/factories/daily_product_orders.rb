FactoryBot.define do
  factory :daily_product_order do
    association :product
    association :client
    association :zone
    route { association :route, zone: zone }
    quantity { 3 }
    day { Date.current }
  end
end
