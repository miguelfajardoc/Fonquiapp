class DefaultProductQuantity < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :zone

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :product_id, uniqueness: { scope: %i[client_id zone_id] }
end
