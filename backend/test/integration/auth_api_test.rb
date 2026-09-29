require "test_helper"

class AuthApiTest < ActionDispatch::IntegrationTest
  test "sign up returns a token that authenticates later requests" do
    post "/api/v1/users", params: { user: { name: "Carol", email: "Carol@Example.com", password: "password123" } }, as: :json

    assert_response :created
    assert_equal "carol@example.com", json.dig("user", "email")
    assert_equal 0, json.dig("user", "reviews_count")

    get "/api/v1/me", headers: { "Authorization" => "Bearer #{json['token']}" }
    assert_response :ok
    assert_equal "Carol", json.dig("user", "name")
  end

  test "sign up with invalid details returns field errors" do
    post "/api/v1/users", params: { user: { name: "", email: "alice@example.com", password: "short" } }, as: :json

    assert_response :unprocessable_content
    assert_equal [ "name", "email", "password" ].sort, json["errors"].keys.sort
    assert_match(/Email has already been taken/, json["error"])
  end

  test "sign in and sign out" do
    post "/api/v1/session", params: { email: "alice@example.com", password: "password123" }, as: :json
    assert_response :created
    headers = { "Authorization" => "Bearer #{json['token']}" }
    assert_equal "Alice Adams", json.dig("user", "name")

    delete "/api/v1/session", headers: headers
    assert_response :no_content

    get "/api/v1/me", headers: headers
    assert_response :unauthorized
  end

  test "sign in with a wrong password fails" do
    post "/api/v1/session", params: { email: "alice@example.com", password: "nope-nope" }, as: :json
    assert_response :unauthorized
    assert_equal "Invalid email or password.", json["error"]
  end

  test "protected endpoints require a valid token" do
    get "/api/v1/me"
    assert_response :unauthorized
    assert_equal "Please sign in to continue.", json["error"]
    assert_match(/Bearer/, response.headers["WWW-Authenticate"])

    get "/api/v1/me", headers: { "Authorization" => "Bearer not-a-real-token" }
    assert_response :unauthorized
  end

  test "lists my reviews newest first with their dish and restaurant" do
    alice = users(:alice)
    Review.create!(user: alice, restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 5, created_at: 2.days.ago)
    Review.create!(user: alice, restaurant_dish: restaurant_dishes(:bangkok_tom_yum), rating: 4, created_at: 1.day.ago)
    Review.create!(user: users(:bob), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 1)

    get "/api/v1/me/reviews", headers: auth_headers(alice)

    assert_response :ok
    assert_equal [ "Tom Yum Soup", "Pad Thai" ], json["reviews"].map { |r| r.dig("dish", "name") }
    assert_equal [ "Bangkok Street Eats", "Thai Orchid Kitchen" ], json["reviews"].map { |r| r.dig("restaurant", "name") }
    assert_equal 2, json.dig("meta", "total_count")
  end

  test "filters my reviews by restaurant" do
    alice = users(:alice)
    Review.create!(user: alice, restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 5)
    Review.create!(user: alice, restaurant_dish: restaurant_dishes(:bangkok_tom_yum), rating: 4)

    get "/api/v1/me/reviews", params: { restaurant_id: restaurants(:bangkok).id }, headers: auth_headers(alice)

    assert_equal [ "Tom Yum Soup" ], json["reviews"].map { |r| r.dig("dish", "name") }
  end

  test "deleting an account requires the password and removes its reviews" do
    alice = users(:alice)
    headers = auth_headers(alice)
    Review.create!(user: alice, restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 5)

    delete "/api/v1/me", params: { password: "wrong-password" }, headers: headers, as: :json
    assert_response :forbidden
    assert User.exists?(alice.id)

    delete "/api/v1/me", params: { password: "password123" }, headers: headers, as: :json
    assert_response :no_content
    assert_not User.exists?(alice.id)
    assert_equal 0, restaurant_dishes(:orchid_pad_thai).reload.reviews_count
  end
end
