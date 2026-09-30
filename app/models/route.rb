class Route < ApplicationRecord
  belongs_to :zone

  has_many :route_stops, -> { order(:position) }, dependent: :destroy
  has_many :clients, through: :route_stops

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end
