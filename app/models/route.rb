class Route < ApplicationRecord
  include Filterable

  belongs_to :zone

  # Declared before route_stops and default_product_quantities so a referenced route aborts before they are destroyed.
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, -> { order(:position) }, dependent: :destroy, inverse_of: :route
  has_many :default_product_quantities, dependent: :destroy
  has_many :clients, through: :route_stops

  accepts_nested_attributes_for :route_stops, allow_destroy: true,
                                              reject_if: proc { |attrs| attrs["client_id"].blank? }

  validates :name, presence: true, uniqueness: { scope: :zone_id }

  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
  scope :filter_by_route_id, ->(route_id) { where(id: route_id) }
  # A subquery rather than a join, so a route is listed once however its stops match.
  scope :filter_by_client_id, ->(client_id) { where(id: RouteStop.where(client_id: client_id).select(:route_id)) }
end
