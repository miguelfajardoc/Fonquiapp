FactoryBot.define do
  factory :default_product_quantity do
    association :route
    association :product
    quantity { 10 }
  end
end
