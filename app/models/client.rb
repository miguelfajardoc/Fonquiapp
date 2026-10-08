class Client < ApplicationRecord
  include Filterable

  belongs_to :zone

  has_many :pending_products, dependent: :restrict_with_error
  has_many :default_product_quantities, dependent: :restrict_with_error
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, dependent: :restrict_with_error
  has_many :routes, through: :route_stops

  validates :name, presence: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :coordinates_complete

  # The location link always mirrors the saved location, so it is never typed by hand.
  before_save :derive_url

  # Contains match on name, ignoring case and accents; typed text is matched literally.
  scope :filter_by_name, ->(name) { where_unaccent_contains("clients.name", name) }
  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
  scope :filter_by_route_id, ->(route_id) { where(id: RouteStop.where(route_id: route_id).select(:client_id)) }

  def to_combobox_display
    name
  end

  def located?
    latitude.present? && longitude.present?
  end

  def coordinates_query
    "#{latitude.to_s("F")},#{longitude.to_s("F")}" if located?
  end

  # What a map should look for: the pin when there is one, otherwise the address.
  def map_query
    coordinates_query || address.presence
  end

  private

  def coordinates_complete
    return if latitude.present? == longitude.present?

    errors.add(latitude.present? ? :longitude : :latitude, :blank)
  end

  def derive_url
    self.url = map_query && GoogleMaps.search_url(map_query)
  end
end
