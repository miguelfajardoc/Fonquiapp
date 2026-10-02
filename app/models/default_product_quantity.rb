class DefaultProductQuantity < ApplicationRecord
  include Filterable

  belongs_to :product
  belongs_to :client
  belongs_to :zone

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: %i[client_id zone_id] }

  scope :filter_by_client_name, ->(name) { joins(:client).where_unaccent_contains("clients.name", name) }
  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
end
