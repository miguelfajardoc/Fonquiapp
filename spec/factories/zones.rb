FactoryBot.define do
  factory :zone do
    sequence(:name) { |n| "Zone #{n}" }
  end
end
