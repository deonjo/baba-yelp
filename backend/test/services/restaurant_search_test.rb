require "test_helper"

class RestaurantSearchTest < ActiveSupport::TestCase
  setup do
    @pad_thai = dishes(:pad_thai)
    @tom_yum = dishes(:tom_yum)
    # Combined (mean of the two dishes) ratings: Orchid 4.5, Basil 3.5, Bangkok 4.75, SF 5.0.
    add_reviews(restaurant_dishes(:orchid_pad_thai), 5, 4)
    add_reviews(restaurant_dishes(:orchid_tom_yum), 5, 4)
    add_reviews(restaurant_dishes(:basil_pad_thai), 4, 3)
    add_reviews(restaurant_dishes(:basil_tom_yum), 4, 3)
    add_reviews(restaurant_dishes(:bangkok_pad_thai), 5)
    add_reviews(restaurant_dishes(:bangkok_tom_yum), 5, 4)
    add_reviews(restaurant_dishes(:lemongrass_pad_thai), 5)
    add_reviews(restaurant_dishes(:sf_pad_thai), 5)
    add_reviews(restaurant_dishes(:sf_tom_yum), 5)
  end

  def search(**options)
    RestaurantSearch.new(dish_ids: [ @pad_thai.id, @tom_yum.id ], latitude: FREMONT[0], longitude: FREMONT[1], **options)
  end

  def names(search)
    search.results.map { |result| result.restaurant.name }
  end

  test "sorts by distance, then rating for restaurants that look equally far away" do
    # Thai Basil (0.17 mi) is a little closer than Thai Orchid (0.22 mi), but both
    # show as "0.2 mi", so the better-rated Thai Orchid comes first.
    assert_equal [ "Thai Orchid Kitchen", "Thai Basil Express", "Bangkok Street Eats" ], names(search)
  end

  test "sorts by rating, then distance" do
    add_reviews(restaurant_dishes(:basil_pad_thai), *[ 5 ] * 10)
    add_reviews(restaurant_dishes(:basil_tom_yum), *[ 5 ] * 10)
    # Thai Basil is now rated 4.75 like Bangkok (both show as 4.8) and is closer.
    results = search(sort: "rating").results
    assert_equal [ "Thai Basil Express", "Bangkok Street Eats", "Thai Orchid Kitchen" ], results.map { |r| r.restaurant.name }
    assert_equal [ 4.8, 4.8, 4.5 ], results.map { |r| r.rating.round(1) }
  end

  test "requires every dish by default, or any dish with match=any" do
    assert_not_includes names(search), "Lemongrass & Lime"
    assert_includes names(search(match: "any")), "Lemongrass & Lime"
  end

  test "only returns restaurants within the radius" do
    assert_not_includes names(search), "Mission Street Thai"
    assert_includes names(search(radius: 30)), "Mission Street Thai"
    assert_equal [ "Thai Basil Express" ], names(search(radius: 0.2))
    assert_equal RestaurantSearch::MAX_RADIUS_MILES, search(radius: 5000).radius
    assert_equal RestaurantSearch::DEFAULT_RADIUS_MILES, search(radius: -1).radius
  end

  test "filters by minimum rating" do
    assert_equal [ "Thai Orchid Kitchen", "Bangkok Street Eats" ], names(search(min_rating: 4.5))
  end

  test "reports per-dish ratings in the order the dishes were requested" do
    result = search.results.find { |r| r.restaurant.name == "Bangkok Street Eats" }
    assert_equal [ @pad_thai.id, @tom_yum.id ], result.restaurant_dishes.map(&:dish_id)
    assert_equal [ 5.0, 4.5 ], result.restaurant_dishes.map(&:average_rating)
    assert_in_delta 4.75, result.rating
    assert_equal 3, result.reviews_count
    assert_in_delta 0.88, result.distance_miles, 0.01
  end

  test "lists unrated restaurants after rated ones" do
    newcomer = Restaurant.create!(name: "Pattaya Kitchen", address: "39100 State St", city: "Fremont", state: "CA",
                                  latitude: 37.5504, longitude: -121.9866)
    newcomer.serve!(@pad_thai)
    newcomer.serve!(@tom_yum)

    distance_order = names(search)
    assert_equal "Pattaya Kitchen", distance_order[2], "same 0.2 mi bucket, but unrated"
    assert_equal "Pattaya Kitchen", names(search(sort: "rating")).last
    assert_nil search.results.find { |r| r.restaurant == newcomer }.rating
  end

  test "searches restaurant names without a location, best rated first" do
    results = RestaurantSearch.new(query: "thai").results
    assert_equal [ "Mission Street Thai", "Thai Orchid Kitchen", "Thai Basil Express" ], results.map { |r| r.restaurant.name }
    assert results.all? { |r| r.distance_miles.nil? }
    assert_equal "rating", RestaurantSearch.new(query: "thai").applied_filters[:sort]
  end

  test "falls back to defaults for unknown options" do
    search = search(sort: "cheapest", match: "some")
    assert_equal "distance", search.sort
    assert_equal "all", search.match
  end
end
