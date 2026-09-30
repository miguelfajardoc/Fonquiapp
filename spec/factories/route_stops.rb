FactoryBot.define do
  factory :route_stop do
    association :route
    association :client
  end
end
