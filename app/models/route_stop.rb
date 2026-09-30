class RouteStop < ApplicationRecord
  belongs_to :route
  belongs_to :client

  acts_as_list scope: :route

  validates :client_id, uniqueness: { scope: :route_id }
end
