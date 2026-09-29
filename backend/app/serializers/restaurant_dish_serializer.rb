class RestaurantDishSerializer
  def self.render(restaurant_dish, include_restaurant: false)
    dish = restaurant_dish.dish
    json = {
      id: restaurant_dish.id,
      restaurant_id: restaurant_dish.restaurant_id,
      dish_id: restaurant_dish.dish_id,
      name: dish.name,
      average_rating: restaurant_dish.average_rating&.round(1),
      reviews_count: restaurant_dish.reviews_count
    }
    json[:cuisine] = CuisineSerializer.summary(dish.cuisine) if dish.association(:cuisine).loaded?
    json[:restaurant] = RestaurantSerializer.render(restaurant_dish.restaurant) if include_restaurant
    json
  end
end
