class RestaurantSerializer
  def self.render(restaurant, distance_miles: nil)
    json = {
      id: restaurant.id,
      name: restaurant.name,
      address: restaurant.address,
      city: restaurant.city,
      state: restaurant.state,
      zip_code: restaurant.zip_code,
      phone: restaurant.phone,
      full_address: restaurant.full_address,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      dishes_count: restaurant.restaurant_dishes_count
    }
    json[:distance_miles] = distance_miles.round(1) if distance_miles
    json
  end

  # A restaurant search result: the restaurant plus distance, the combined rating
  # of the searched dishes and each searched dish's own rating.
  def self.search_result(result)
    render(result.restaurant, distance_miles: result.distance_miles).merge(
      distance_miles: result.distance_miles&.round(1),
      rating: result.rating&.round(1),
      reviews_count: result.reviews_count,
      dishes: result.restaurant_dishes.map { |restaurant_dish| RestaurantDishSerializer.render(restaurant_dish) }
    )
  end
end
