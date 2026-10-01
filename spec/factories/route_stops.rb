FactoryBot.define do
  factory :route_stop do
    association :route
    client { create(:client, zone: route&.zone || create(:zone)) }
  end
end
