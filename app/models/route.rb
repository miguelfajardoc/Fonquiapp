class Route < ApplicationRecord
  belongs_to :zone

  has_many :route_stops, -> { order(:position) }, dependent: :destroy
  has_many :clients, through: :route_stops

  accepts_nested_attributes_for :route_stops, allow_destroy: true,
    reject_if: proc { |attrs| attrs["client_id"].blank? }

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end
