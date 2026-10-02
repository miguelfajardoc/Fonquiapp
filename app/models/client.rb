class Client < ApplicationRecord
  include Filterable

  belongs_to :zone

  has_many :pending_products, dependent: :restrict_with_error
  has_many :default_product_quantities, dependent: :restrict_with_error
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, dependent: :restrict_with_error
  has_many :routes, through: :route_stops

  validates :name, presence: true

  # Contains match on name, ignoring case and accents; typed text is matched literally.
  scope :filter_by_name, lambda { |name|
    where("unaccent(clients.name) ILIKE unaccent(?)", "%#{sanitize_sql_like(name)}%")
  }
  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
  scope :filter_by_route_id, ->(route_id) { where(id: RouteStop.where(route_id: route_id).select(:client_id)) }

  def to_combobox_display
    name
  end
end
