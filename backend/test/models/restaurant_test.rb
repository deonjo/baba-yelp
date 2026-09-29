require "test_helper"

class RestaurantTest < ActiveSupport::TestCase
  def new_restaurant(**attrs)
    Restaurant.new({ name: "Siam Garden", address: "40900 Fremont Blvd", city: "Fremont", state: "ca", zip_code: "94538" }.merge(attrs))
  end

  test "normalizes the state to upper case and builds a full address" do
    restaurant = new_restaurant(latitude: 37.5262, longitude: -121.9679)
    assert restaurant.valid?
    assert_equal "CA", restaurant.state
    assert_equal "40900 Fremont Blvd, Fremont, CA 94538", restaurant.full_address
  end

  test "geocodes the address when coordinates are missing" do
    Geocoder::Lookup::Test.add_stub("40900 Fremont Blvd, Fremont, CA 94538", [ { "coordinates" => [ 37.5262, -121.9679 ] } ])

    restaurant = new_restaurant
    assert restaurant.save
    assert_in_delta 37.5262, restaurant.latitude
    assert_in_delta(-121.9679, restaurant.longitude)
  end

  test "does not geocode when coordinates are given" do
    Geocoder.stub(:search, ->(*) { flunk "should not geocode" }) do
      assert new_restaurant(latitude: 37.5, longitude: -121.9).save
    end
  end

  test "reports an address that cannot be found" do
    Geocoder::Lookup::Test.add_stub("40900 Fremont Blvd, Fremont, CA 94538", [])

    restaurant = new_restaurant
    assert_not restaurant.valid?
    assert_match(/could not be found on the map/, restaurant.errors[:address].first)
  end

  test "reports when the geocoding service is down" do
    Geocoder.stub(:search, ->(*) { raise Geocoder::ServiceUnavailable }) do
      restaurant = new_restaurant
      assert_not restaurant.valid?
      assert_match(/could not be looked up right now/, restaurant.errors[:address].first)
    end
  end

  test "rejects out of range coordinates" do
    restaurant = new_restaurant(latitude: 91, longitude: -200)
    assert_not restaurant.valid?
    assert restaurant.errors[:latitude].any?
    assert restaurant.errors[:longitude].any?
  end

  test "finds a nearby restaurant with the same name as a duplicate" do
    orchid = restaurants(:thai_orchid)
    duplicate = Restaurant.new(name: "thai orchid kitchen!", address: "39170 State Street", city: "Fremont", state: "CA",
                               latitude: orchid.latitude + 0.0005, longitude: orchid.longitude)
    assert_equal orchid, duplicate.nearby_duplicate

    far_away = Restaurant.new(name: "Thai Orchid Kitchen", address: "1 Main St", city: "Oakland", state: "CA",
                              latitude: 37.8044, longitude: -122.2712)
    assert_nil far_away.nearby_duplicate

    different_name = Restaurant.new(name: "Thai Orchid Cafe", address: "39170 State St", city: "Fremont", state: "CA",
                                    latitude: orchid.latitude, longitude: orchid.longitude)
    assert_nil different_name.nearby_duplicate
  end

  test "serve! links a dish once" do
    restaurant = restaurants(:burger_joint)

    link = assert_difference -> { restaurant.restaurant_dishes.count }, 1 do
      restaurant.serve!(dishes(:hot_dog), added_by: users(:alice))
    end
    assert_equal users(:alice), link.added_by

    assert_no_difference -> { RestaurantDish.count } do
      assert_equal link, restaurant.serve!(dishes(:hot_dog))
    end
    assert_equal 2, restaurant.reload.restaurant_dishes_count
  end
end
