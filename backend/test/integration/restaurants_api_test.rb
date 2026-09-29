require "test_helper"

class RestaurantsApiTest < ActionDispatch::IntegrationTest
  setup do
    add_reviews(restaurant_dishes(:orchid_pad_thai), 5, 4)
    add_reviews(restaurant_dishes(:orchid_tom_yum), 5)
    add_reviews(restaurant_dishes(:bangkok_pad_thai), 5)
    add_reviews(restaurant_dishes(:bangkok_tom_yum), 5, 5)
  end

  def search_params(**overrides)
    { dish_ids: [ dishes(:pad_thai).id, dishes(:tom_yum).id ], lat: FREMONT[0], lng: FREMONT[1] }.merge(overrides)
  end

  test "finds nearby restaurants serving all the dishes, closest first" do
    get "/api/v1/restaurants", params: search_params

    assert_response :ok
    assert_equal [ "Thai Orchid Kitchen", "Thai Basil Express", "Bangkok Street Eats" ], json["restaurants"].map { |r| r["name"] }

    orchid = json["restaurants"].first
    assert_equal 0.2, orchid["distance_miles"]
    assert_equal 4.8, orchid["rating"]
    assert_equal 3, orchid["reviews_count"]
    assert_equal "39170 State St, Fremont, CA 94538", orchid["full_address"]
    assert_equal [ [ "Pad Thai", 4.5, 2 ], [ "Tom Yum Soup", 5.0, 1 ] ],
                 orchid["dishes"].map { |d| [ d["name"], d["average_rating"], d["reviews_count"] ] }
    assert_equal restaurant_dishes(:orchid_pad_thai).id, orchid["dishes"].first["id"]

    basil = json["restaurants"].second
    assert_nil basil["rating"]
    assert_equal [ nil, nil ], basil["dishes"].map { |d| d["average_rating"] }

    assert_equal({ "page" => 1, "per_page" => 20, "total_count" => 3, "total_pages" => 1, "q" => nil,
                   "dish_ids" => search_params[:dish_ids], "match" => "all", "sort" => "distance",
                   "latitude" => FREMONT[0], "longitude" => FREMONT[1], "radius_miles" => 10.0, "min_rating" => nil },
                 json["meta"])
  end

  test "sorts by rating and accepts comma-separated dish ids" do
    get "/api/v1/restaurants", params: search_params(dish_ids: search_params[:dish_ids].join(","), sort: "rating")

    assert_response :ok
    assert_equal [ "Bangkok Street Eats", "Thai Orchid Kitchen", "Thai Basil Express" ], json["restaurants"].map { |r| r["name"] }
    assert_equal "rating", json.dig("meta", "sort")
  end

  test "supports match=any, radius, min_rating and paging" do
    get "/api/v1/restaurants", params: search_params(match: "any", radius: 50)
    assert_equal 5, json["restaurants"].size

    get "/api/v1/restaurants", params: search_params(min_rating: 4.9)
    assert_equal [ "Bangkok Street Eats" ], json["restaurants"].map { |r| r["name"] }

    get "/api/v1/restaurants", params: search_params(per_page: 2, page: 2)
    assert_equal [ "Bangkok Street Eats" ], json["restaurants"].map { |r| r["name"] }
    assert_equal 2, json.dig("meta", "total_pages")
  end

  test "searches by restaurant name" do
    get "/api/v1/restaurants", params: { q: "burger", lat: FREMONT[0], lng: FREMONT[1] }

    assert_equal [ "Mission Peak Burgers" ], json["restaurants"].map { |r| r["name"] }
    assert_equal [], json["restaurants"].first["dishes"]
  end

  test "rejects malformed search parameters" do
    get "/api/v1/restaurants", params: { lat: FREMONT[0] }
    assert_response :bad_request
    assert_equal "lat and lng must be given together.", json["error"]

    get "/api/v1/restaurants", params: { lat: "north", lng: FREMONT[1] }
    assert_response :bad_request

    get "/api/v1/restaurants", params: { dish_ids: "1,pad-thai" }
    assert_response :bad_request

    get "/api/v1/restaurants", params: { dish_ids: (1..11).to_a }
    assert_response :bad_request
  end

  test "shows a restaurant with its dishes, best rated first" do
    get "/api/v1/restaurants/#{restaurants(:thai_orchid).id}", params: { lat: FREMONT[0], lng: FREMONT[1] }

    assert_response :ok
    restaurant = json["restaurant"]
    assert_equal "Thai Orchid Kitchen", restaurant["name"]
    assert_equal "(510) 555-0101", restaurant["phone"]
    assert_equal 0.2, restaurant["distance_miles"]
    assert_equal 4.8, restaurant["rating"]
    assert_equal [ "Tom Yum Soup", "Pad Thai" ], restaurant["dishes"].map { |d| d["name"] }
    assert_equal "Thai", restaurant["dishes"].first.dig("cuisine", "name")
  end

  test "shows a restaurant without a distance when no location is given" do
    get "/api/v1/restaurants/#{restaurants(:burger_joint).id}"
    assert_response :ok
    assert_not json["restaurant"].key?("distance_miles")

    get "/api/v1/restaurants/0"
    assert_response :not_found
  end

  test "adds a restaurant at the given coordinates" do
    post "/api/v1/restaurants", params: { restaurant: { name: "Krua Thai Cafe", address: "1780 Decoto Rd", city: "Union City",
                                                        state: "ca", zip_code: "94587", latitude: 37.5901, longitude: -122.0290 } },
                                headers: auth_headers(users(:alice)), as: :json

    assert_response :created
    assert_equal "CA", json.dig("restaurant", "state")
    assert_equal users(:alice), Restaurant.find(json.dig("restaurant", "id")).created_by
  end

  test "adds a restaurant by geocoding its address" do
    Geocoder::Lookup::Test.add_stub("1780 Decoto Rd, Union City, CA", [ { "coordinates" => [ 37.5901, -122.0290 ] } ])

    post "/api/v1/restaurants", params: { restaurant: { name: "Krua Thai Cafe", address: "1780 Decoto Rd", city: "Union City", state: "CA" } },
                                headers: auth_headers(users(:alice)), as: :json

    assert_response :created
    assert_equal [ 37.5901, -122.029 ], json["restaurant"].values_at("latitude", "longitude")
  end

  test "adding a restaurant that already exists nearby returns the existing one" do
    assert_no_difference -> { Restaurant.count } do
      post "/api/v1/restaurants", params: { restaurant: { name: "Thai Orchid Kitchen", address: "39170 State Street", city: "Fremont",
                                                          state: "CA", latitude: 37.5509, longitude: -121.9862 } },
                                  headers: auth_headers(users(:alice)), as: :json
    end

    assert_response :conflict
    assert_equal restaurants(:thai_orchid).id, json.dig("restaurant", "id")
    assert_match(/already listed/, json["error"])
  end

  test "adding a restaurant validates its fields and requires signing in" do
    post "/api/v1/restaurants", params: { restaurant: { name: "", address: "", city: "Fremont", state: "CA" } },
                                headers: auth_headers(users(:alice)), as: :json
    assert_response :unprocessable_content
    assert json.dig("errors", "name").present?
    assert json.dig("errors", "address").present?

    post "/api/v1/restaurants", params: { restaurant: { name: "Nope" } }, as: :json
    assert_response :unauthorized
  end
end
