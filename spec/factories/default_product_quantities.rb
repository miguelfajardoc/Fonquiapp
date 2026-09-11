FactoryBot.define do
  factory :default_product_quantity do
    association :product
    association :client
    association :zone
    quantity { 10 }
  end
end
