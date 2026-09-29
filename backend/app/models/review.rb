class Review < ApplicationRecord
  belongs_to :user
  belongs_to :restaurant_dish

  normalizes :body, with: ->(body) { body.strip.presence }

  validates :rating, presence: true, numericality: { only_integer: true, in: 1..5 }
  validates :body, length: { maximum: 2000 }
  validates :user_id, uniqueness: { scope: :restaurant_dish_id, message: "has already reviewed this dish here" }

  after_save :refresh_restaurant_dish_rating
  after_destroy :refresh_restaurant_dish_rating

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  private

  def refresh_restaurant_dish_rating
    restaurant_dish.refresh_rating!
  end
end
