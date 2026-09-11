class Product < ApplicationRecord
  has_many :pending_products, dependent: :restrict_with_error
  has_many :default_product_quantities, dependent: :restrict_with_error
  has_many :daily_product_orders, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
