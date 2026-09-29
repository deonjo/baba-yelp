require "test_helper"

class ReviewsApiTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @orchid = restaurants(:thai_orchid)
  end

  def post_reviews(restaurant, reviews, user: @alice)
    post "/api/v1/restaurants/#{restaurant.id}/reviews", params: { reviews: reviews }, headers: auth_headers(user), as: :json
  end

  test "reviews several dishes at a restaurant in one go, adding new dishes to its menu" do
    restaurant = restaurants(:burger_joint)

    assert_difference -> { Review.count } => 2, -> { restaurant.restaurant_dishes.count } => 1 do
      post_reviews(restaurant, [
        { dish_id: dishes(:hamburger).id, rating: 5, body: "Juicy and perfectly charred." },
        { dish_id: dishes(:hot_dog).id, rating: 3 }
      ])
    end

    assert_response :created
    assert_equal [ [ "Hamburger", 5 ], [ "Hot Dog", 3 ] ], json["reviews"].map { |r| [ r.dig("dish", "name"), r["rating"] ] }
    assert_equal "Alice Adams", json["reviews"].first.dig("user", "name")
    hot_dog = restaurant.restaurant_dishes.find_by!(dish: dishes(:hot_dog))
    assert_equal @alice, hot_dog.added_by
    assert_equal [ 1, 3.0 ], [ hot_dog.reviews_count, hot_dog.average_rating ]
  end

  test "reviewing a dish again replaces the previous review" do
    post_reviews(@orchid, [ { dish_id: dishes(:pad_thai).id, rating: 2, body: "Too sweet." } ])
    assert_response :created

    assert_no_difference -> { Review.count } do
      post_reviews(@orchid, [ { dish_id: dishes(:pad_thai).id, rating: 4, body: "Better this time." } ])
    end

    assert_response :ok
    review = @alice.reviews.sole
    assert_equal [ 4, "Better this time." ], [ review.rating, review.body ]
    assert_equal 4.0, restaurant_dishes(:orchid_pad_thai).reload.average_rating
  end

  test "saves nothing when any review is invalid" do
    assert_no_difference -> { Review.count } do
      assert_no_difference -> { RestaurantDish.count } do
        post_reviews(@orchid, [
          { dish_id: dishes(:green_curry).id, rating: 5 },
          { dish_id: dishes(:pad_thai).id, rating: 9 },
          { dish_id: 0, rating: 5 }
        ])
      end
    end

    assert_response :unprocessable_content
    assert_equal [ dishes(:pad_thai).id, 0 ], json["errors"].map { |e| e["dish_id"] }
    assert_equal [ "Rating must be in 1..5" ], json["errors"].first["errors"]
    assert_equal [ "Dish not found" ], json["errors"].second["errors"]
  end

  test "rejects malformed review submissions" do
    post_reviews(@orchid, [])
    assert_response :bad_request

    post_reviews(@orchid, [ { dish_id: dishes(:pad_thai).id, rating: 5 }, { dish_id: dishes(:pad_thai).id, rating: 4 } ])
    assert_response :bad_request
    assert_match(/only be reviewed once/, json["error"])

    post_reviews(@orchid, [ { rating: 5 } ])
    assert_response :bad_request

    post_reviews(@orchid, Array.new(11) { |i| { dish_id: i + 1, rating: 5 } })
    assert_response :bad_request
  end

  test "reviewing requires signing in" do
    post "/api/v1/restaurants/#{@orchid.id}/reviews", params: { reviews: [ { dish_id: dishes(:pad_thai).id, rating: 5 } ] }, as: :json
    assert_response :unauthorized
  end

  test "lists a restaurant dish's reviews, newest first" do
    restaurant_dish = restaurant_dishes(:orchid_pad_thai)
    Review.create!(user: @alice, restaurant_dish: restaurant_dish, rating: 5, body: "Great", created_at: 3.days.ago)
    Review.create!(user: users(:bob), restaurant_dish: restaurant_dish, rating: 3, body: "Okay", created_at: 1.day.ago)

    get "/api/v1/restaurant_dishes/#{restaurant_dish.id}/reviews"

    assert_response :ok
    assert_equal [ [ "Bob Brown", 3, "Okay" ], [ "Alice Adams", 5, "Great" ] ],
                 json["reviews"].map { |r| [ r.dig("user", "name"), r["rating"], r["body"] ] }
    assert_not json["reviews"].first["user"].key?("email")
  end

  test "edits and deletes your own review" do
    review = Review.create!(user: @alice, restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 2)

    patch "/api/v1/reviews/#{review.id}", params: { review: { rating: 5, body: "Changed my mind!" } }, headers: auth_headers(@alice), as: :json
    assert_response :ok
    assert_equal [ 5, "Changed my mind!" ], json["review"].values_at("rating", "body")
    assert_equal 5.0, restaurant_dishes(:orchid_pad_thai).reload.average_rating

    patch "/api/v1/reviews/#{review.id}", params: { review: { rating: 0 } }, headers: auth_headers(@alice), as: :json
    assert_response :unprocessable_content

    delete "/api/v1/reviews/#{review.id}", headers: auth_headers(@alice)
    assert_response :no_content
    assert_equal [ 0, nil ], restaurant_dishes(:orchid_pad_thai).reload.values_at(:reviews_count, :average_rating)
  end

  test "cannot edit or delete someone else's review" do
    review = Review.create!(user: users(:bob), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 2)

    patch "/api/v1/reviews/#{review.id}", params: { review: { rating: 5 } }, headers: auth_headers(@alice), as: :json
    assert_response :not_found

    delete "/api/v1/reviews/#{review.id}", headers: auth_headers(@alice)
    assert_response :not_found
    assert_equal 2, review.reload.rating
  end
end
