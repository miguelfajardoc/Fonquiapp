class Route < ApplicationRecord
  belongs_to :zone

  # Declared before route_stops and default_product_quantities so a referenced route aborts before they are destroyed.
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, -> { order(:position) }, dependent: :destroy, inverse_of: :route
  has_many :default_product_quantities, dependent: :destroy
  has_many :clients, through: :route_stops

  accepts_nested_attributes_for :route_stops, allow_destroy: true,
                                              reject_if: proc { |attrs| attrs["client_id"].blank? }

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end
