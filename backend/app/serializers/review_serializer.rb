class ReviewSerializer
  def self.render(review, include_context: false)
    json = {
      id: review.id,
      restaurant_dish_id: review.restaurant_dish_id,
      rating: review.rating,
      body: review.body,
      user: UserSerializer.render(review.user),
      created_at: review.created_at.utc.iso8601,
      updated_at: review.updated_at.utc.iso8601
    }
    if include_context
      restaurant_dish = review.restaurant_dish
      json[:dish] = { id: restaurant_dish.dish.id, name: restaurant_dish.dish.name }
      json[:restaurant] = {
        id: restaurant_dish.restaurant.id,
        name: restaurant_dish.restaurant.name,
        city: restaurant_dish.restaurant.city
      }
    end
    json
  end
end
