class PendingProduct < ApplicationRecord
  include Filterable

  belongs_to :product
  belongs_to :client
  belongs_to :zone

  enum :state, { pending: 0, delivered: 1, canceled: 9 }

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  scope :filter_by_client_name, ->(name) { joins(:client).where_unaccent_contains("clients.name", name) }
  scope :filter_by_zone_id, ->(zone_id) { where(zone_id: zone_id) }
  # Unknown states (e.g. a hand-edited URL) leave the list unfiltered instead of raising.
  scope :filter_by_state, ->(state) { states.key?(state) ? where(state: state) : all }
end
