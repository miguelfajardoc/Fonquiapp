class DailyProductOrder < ApplicationRecord
  belongs_to :product
  belongs_to :client
  belongs_to :zone

  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
  validates :day, presence: true
end
