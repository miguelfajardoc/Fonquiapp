FactoryBot.define do
  factory :pending_product do
    association :product
    association :client
    association :zone
    quantity { 5 }
    state { :pending }
  end
end
