class DefaultProductQuantity < ApplicationRecord
  include Filterable

  belongs_to :route
  belongs_to :product

  delegate :zone, to: :route

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :route_id }

  scope :filter_by_zone_id, ->(zone_id) { where(route_id: Route.where(zone_id: zone_id).select(:id)) }
  scope :filter_by_route_id, ->(route_id) { where(route_id: route_id) }
end
