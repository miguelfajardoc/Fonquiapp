class DailyProductOrder < ApplicationRecord
  include Filterable

  belongs_to :product
  belongs_to :client
  belongs_to :zone
  belongs_to :route

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :day, presence: true

  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
  scope :filter_by_route_id, ->(route_id) { where(route_id: route_id) }
end
