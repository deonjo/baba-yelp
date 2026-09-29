require "test_helper"

class RestaurantDishesApiTest < ActionDispatch::IntegrationTest
  test "shows a dish at a restaurant with its rating breakdown" do
    restaurant_dish = add_reviews(restaurant_dishes(:orchid_pad_thai), 5, 5, 4, 2)

    get "/api/v1/restaurant_dishes/#{restaurant_dish.id}"

    assert_response :ok
    body = json["restaurant_dish"]
    assert_equal "Pad Thai", body["name"]
    assert_equal "Thai Orchid Kitchen", body.dig("restaurant", "name")
    assert_equal 4.0, body["average_rating"]
    assert_equal 4, body["reviews_count"]
    assert_equal({ "5" => 2, "4" => 1, "3" => 0, "2" => 1, "1" => 0 }, body["rating_distribution"])
    assert_nil body["my_review"]
  end

  test "includes your own review when signed in" do
    alice = users(:alice)
    review = Review.create!(user: alice, restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 4, body: "Nice")

    get "/api/v1/restaurant_dishes/#{restaurant_dishes(:orchid_pad_thai).id}", headers: auth_headers(alice)

    assert_equal review.id, json.dig("restaurant_dish", "my_review", "id")
    assert_equal "Nice", json.dig("restaurant_dish", "my_review", "body")
  end

  test "adds a dish to a restaurant's menu, once" do
    restaurant = restaurants(:burger_joint)
    params = { restaurant_id: restaurant.id, dish_id: dishes(:hot_dog).id }

    post "/api/v1/restaurant_dishes", params: params, headers: auth_headers(users(:alice)), as: :json
    assert_response :created
    id = json.dig("restaurant_dish", "id")
    assert_equal "Hot Dog", json.dig("restaurant_dish", "name")
    assert_equal "Mission Peak Burgers", json.dig("restaurant_dish", "restaurant", "name")

    post "/api/v1/restaurant_dishes", params: params, headers: auth_headers(users(:bob)), as: :json
    assert_response :ok
    assert_equal id, json.dig("restaurant_dish", "id")
  end

  test "adding to a menu requires signing in and existing records" do
    post "/api/v1/restaurant_dishes", params: { restaurant_id: restaurants(:burger_joint).id, dish_id: dishes(:hot_dog).id }, as: :json
    assert_response :unauthorized

    post "/api/v1/restaurant_dishes", params: { restaurant_id: 0, dish_id: dishes(:hot_dog).id }, headers: auth_headers(users(:alice)), as: :json
    assert_response :not_found

    post "/api/v1/restaurant_dishes", params: { restaurant_id: restaurants(:burger_joint).id }, headers: auth_headers(users(:alice)), as: :json
    assert_response :bad_request
  end
end
