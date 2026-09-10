class Zone < ApplicationRecord
  has_many :clients, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
