class Zone < ApplicationRecord
  has_many :clients, dependent: :restrict_with_error

  has_many :pending_products, dependent: :restrict_with_error
  has_many :default_product_quantities, dependent: :restrict_with_error
  has_many :daily_product_orders, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
