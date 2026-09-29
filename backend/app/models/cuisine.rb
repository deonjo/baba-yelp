class Cuisine < ApplicationRecord
  has_many :dishes, dependent: :restrict_with_error

  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:name) }
end
