# A dish as served by a particular restaurant ("Pad Thai at Thai Orchid").
# Reviews and ratings belong here, not to the restaurant as a whole.
class RestaurantDish < ApplicationRecord
  belongs_to :restaurant, counter_cache: true
  belongs_to :dish, counter_cache: true
  belongs_to :added_by, class_name: "User", optional: true
  has_many :reviews, dependent: :destroy

  validates :dish_id, uniqueness: { scope: :restaurant_id, message: "is already on this restaurant's menu" }

  scope :best_first, -> {
    order(Arel.sql("restaurant_dishes.average_rating IS NULL, restaurant_dishes.average_rating DESC, restaurant_dishes.reviews_count DESC"))
  }

  # Overall rating for a group of dishes: the mean of each rated dish's average,
  # so every dish counts equally no matter how many reviews it has.
  # Returns [rating or nil, total review count].
  def self.combined_rating(restaurant_dishes)
    rated = restaurant_dishes.select(&:average_rating)
    rating = rated.sum(&:average_rating) / rated.size if rated.any?
    [ rating, restaurant_dishes.sum(&:reviews_count) ]
  end

  def refresh_rating!
    count, average = reviews.pick(Arel.sql("COUNT(*)"), Arel.sql("AVG(rating)"))
    update_columns(reviews_count: count, average_rating: average&.to_f&.round(2), updated_at: Time.current)
  end

  # { 5 => count, 4 => count, ..., 1 => count }
  def rating_distribution
    counts = reviews.group(:rating).count
    5.downto(1).to_h { |stars| [ stars, counts.fetch(stars, 0) ] }
  end
end
