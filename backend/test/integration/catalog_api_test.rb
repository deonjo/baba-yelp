require "test_helper"

class CatalogApiTest < ActionDispatch::IntegrationTest
  test "lists cuisines alphabetically with dish counts" do
    get "/api/v1/cuisines"

    assert_response :ok
    assert_equal [ [ "American", 2 ], [ "Thai", 3 ] ], json["cuisines"].map { |c| [ c["name"], c["dishes_count"] ] }
  end

  test "searches dishes by name, alias and cuisine" do
    get "/api/v1/dishes", params: { q: "burger" }
    assert_equal [ "Hamburger" ], json["dishes"].map { |d| d["name"] }

    get "/api/v1/dishes", params: { q: "tom yam" }
    dish = json["dishes"].sole
    assert_equal "Tom Yum Soup", dish["name"]
    assert_equal [ "Tom Yam", "Tom Yum Goong" ], dish["aliases"]
    assert_equal({ "id" => cuisines(:thai).id, "name" => "Thai", "emoji" => "🇹🇭" }, dish["cuisine"])
    assert_equal 4, dish["restaurants_count"]
  end

  test "lists a cuisine's dishes, most widely served first" do
    get "/api/v1/dishes", params: { cuisine_id: cuisines(:thai).id }

    assert_equal [ "Pad Thai", "Tom Yum Soup", "Green Curry" ], json["dishes"].map { |d| d["name"] }
    assert_equal({ "page" => 1, "per_page" => 50, "total_count" => 3, "total_pages" => 1 }, json["meta"])
  end

  test "paginates dishes" do
    get "/api/v1/dishes", params: { per_page: 2, page: 3 }
    assert_equal 1, json["dishes"].size
    assert_equal 3, json.dig("meta", "total_pages")
  end

  test "shows a dish" do
    get "/api/v1/dishes/#{dishes(:pad_thai).id}"
    assert_response :ok
    assert_equal "Stir-fried rice noodles.", json.dig("dish", "description")

    get "/api/v1/dishes/0"
    assert_response :not_found
  end

  test "signed-in users can add dishes" do
    post "/api/v1/dishes", params: { dish: { name: "Khao Man Gai", cuisine_id: cuisines(:thai).id, aliases: "Hainanese chicken rice" } },
                           headers: auth_headers(users(:alice)), as: :json

    assert_response :created
    assert_equal "Khao Man Gai", json.dig("dish", "name")
    assert_equal users(:alice), Dish.find(json.dig("dish", "id")).created_by
  end

  test "adding a duplicate dish or one without a cuisine fails" do
    post "/api/v1/dishes", params: { dish: { name: "PAD THAI", cuisine_id: cuisines(:thai).id } },
                           headers: auth_headers(users(:alice)), as: :json
    assert_response :unprocessable_content
    assert_equal [ "has already been taken" ], json.dig("errors", "name")

    post "/api/v1/dishes", params: { dish: { name: "Mystery Stew" } }, headers: auth_headers(users(:alice)), as: :json
    assert_response :unprocessable_content
    assert json.dig("errors", "cuisine").present?
  end

  test "adding a dish requires signing in" do
    post "/api/v1/dishes", params: { dish: { name: "Khao Man Gai", cuisine_id: cuisines(:thai).id } }, as: :json
    assert_response :unauthorized
  end
end
