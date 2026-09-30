FactoryBot.define do
  factory :route do
    association :zone
    sequence(:name) { |n| "Ruta #{n}" }
  end
end
