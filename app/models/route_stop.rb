class RouteStop < ApplicationRecord
  belongs_to :route
  belongs_to :client

  acts_as_list scope: :route

  validates :client_id, uniqueness: { scope: :route_id }
  validate :client_in_routes_zone

  private

  def client_in_routes_zone
    return if route.nil? || client.nil?

    errors.add(:client, :invalid) unless client.zone&.id == route.zone&.id
  end
end
