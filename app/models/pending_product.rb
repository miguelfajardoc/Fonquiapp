class PendingProduct < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :zone

  enum :state, { pending: 0, delivered: 1, canceled: 9 }

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
