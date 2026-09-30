class Client < ApplicationRecord
  belongs_to :zone

  has_many :pending_products, dependent: :restrict_with_error
  has_many :default_product_quantities, dependent: :restrict_with_error
  has_many :daily_product_orders, dependent: :restrict_with_error
  has_many :route_stops, dependent: :restrict_with_error

  validates :name, presence: true

  def to_combobox_display
    name
  end
end
