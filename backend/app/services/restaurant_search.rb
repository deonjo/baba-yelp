# Finds restaurants, optionally filtered by name, by the dishes they serve and by
# distance from a point, and sorts them for display.
#
# Sorting ("distance then rating" / "rating then distance") compares distances
# and ratings at the precision the app displays them (0.1 mi and 0.1 stars), so
# that restaurants that look equally far away are ordered by rating and vice versa.
class RestaurantSearch
  SORTS = %w[distance rating].freeze
  MATCHES = %w[all any].freeze
  DEFAULT_RADIUS_MILES = 10.0
  MAX_RADIUS_MILES = 100.0
  MAX_DISHES = 10

  Result = Data.define(:restaurant, :distance_miles, :rating, :reviews_count, :restaurant_dishes)

  attr_reader :query, :dish_ids, :latitude, :longitude, :radius, :sort, :match, :min_rating

  def initialize(query: nil, dish_ids: [], latitude: nil, longitude: nil, radius: nil, sort: nil, match: nil, min_rating: nil)
    @query = query.to_s.squish.presence
    @dish_ids = Array(dish_ids).map(&:to_i).select(&:positive?).uniq.first(MAX_DISHES)
    @latitude = latitude&.to_f
    @longitude = longitude&.to_f
    @radius = parse_radius(radius)
    @sort = SORTS.include?(sort.to_s) ? sort.to_s : "distance"
    @match = MATCHES.include?(match.to_s) ? match.to_s : "all"
    @min_rating = min_rating.to_f.clamp(0.0, 5.0) if min_rating.to_f.positive?
  end

  def location?
    !latitude.nil? && !longitude.nil?
  end

  def results
    @results ||= begin
      restaurants = candidates.to_a
      dishes_by_restaurant = restaurant_dishes_for(restaurants)
      rows = restaurants.map { |restaurant| build_result(restaurant, dishes_by_restaurant.fetch(restaurant.id, [])) }
      rows = rows.select { |row| row.distance_miles <= radius } if location?
      rows = rows.select { |row| row.rating && row.rating.round(1) >= min_rating } if min_rating
      rows.sort_by { |row| sort_key(row) }
    end
  end

  def applied_filters
    {
      q: query,
      dish_ids: dish_ids,
      match: match,
      sort: location? ? sort : "rating",
      latitude: latitude,
      longitude: longitude,
      radius_miles: (radius if location?),
      min_rating: min_rating
    }
  end

  private

  def parse_radius(value)
    radius = value.present? ? value.to_f : DEFAULT_RADIUS_MILES
    radius = DEFAULT_RADIUS_MILES unless radius.positive?
    [ radius, MAX_RADIUS_MILES ].min
  end

  def candidates
    scope = Restaurant.all
    scope = scope.where("restaurants.name LIKE ?", "%#{Restaurant.sanitize_sql_like(query)}%") if query
    if location?
      box = GeoMath.bounding_box(latitude, longitude, radius)
      scope = scope.where(latitude: box.latitudes, longitude: box.longitudes)
    end
    if dish_ids.any?
      serving = RestaurantDish.where(dish_id: dish_ids).group(:restaurant_id)
      serving = serving.having("COUNT(DISTINCT restaurant_dishes.dish_id) = ?", dish_ids.size) if match == "all"
      scope = scope.where(id: serving.select(:restaurant_id))
    end
    scope
  end

  def restaurant_dishes_for(restaurants)
    scope = RestaurantDish.where(restaurant_id: restaurants.map(&:id))
    scope = scope.where(dish_id: dish_ids).includes(:dish) if dish_ids.any?
    scope.to_a.group_by(&:restaurant_id)
  end

  def build_result(restaurant, restaurant_dishes)
    rating, reviews_count = RestaurantDish.combined_rating(restaurant_dishes)
    matched = dish_ids.any? ? restaurant_dishes.sort_by { |restaurant_dish| dish_ids.index(restaurant_dish.dish_id) } : []
    Result.new(
      restaurant: restaurant,
      distance_miles: (restaurant.distance_from(latitude, longitude) if location?),
      rating: rating,
      reviews_count: reviews_count,
      restaurant_dishes: matched
    )
  end

  def sort_key(row)
    # Ratings sort descending; unrated restaurants go after all rated ones.
    rating_key = row.rating ? -row.rating.round(1) : 1
    tie_breakers = [ row.restaurant.name.downcase, row.restaurant.id ]

    if sort == "distance" && location?
      [ row.distance_miles.round(1), rating_key, row.distance_miles, *tie_breakers ]
    else
      [ rating_key, row.distance_miles || 0, -row.reviews_count, *tie_breakers ]
    end
  end
end
