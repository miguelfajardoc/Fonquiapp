class Route < ApplicationRecord
  belongs_to :zone

  # Declared before route_stops so a referenced route aborts before its stops are destroyed.
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, -> { order(:position) }, dependent: :destroy
  has_many :clients, through: :route_stops

  accepts_nested_attributes_for :route_stops, allow_destroy: true,
    reject_if: proc { |attrs| attrs["client_id"].blank? }

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end
