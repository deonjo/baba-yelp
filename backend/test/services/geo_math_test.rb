require "test_helper"

class GeoMathTest < ActiveSupport::TestCase
  test "computes great-circle distances in miles" do
    assert_in_delta 0.0, GeoMath.distance_miles(*FREMONT, *FREMONT), 0.0001
    # Fremont to downtown San Francisco is about 28.5 miles as the crow flies.
    assert_in_delta 28.5, GeoMath.distance_miles(*FREMONT, 37.7793, -122.4193), 0.2
    # One degree of latitude is about 69 miles.
    assert_in_delta 69.1, GeoMath.distance_miles(37.0, -122.0, 38.0, -122.0), 0.2
  end

  test "bounding box contains every point within the radius" do
    box = GeoMath.bounding_box(*FREMONT, 10)
    [ 0, 90, 180, 270 ].each do |bearing|
      # A point ~9.9 miles away in each compass direction.
      lat = FREMONT[0] + 9.9 / 69.0 * Math.cos(GeoMath.radians(bearing))
      lng = FREMONT[1] + 9.9 / (69.0 * Math.cos(GeoMath.radians(FREMONT[0]))) * Math.sin(GeoMath.radians(bearing))
      assert_operator GeoMath.distance_miles(*FREMONT, lat, lng), :<, 10
      assert box.latitudes.cover?(lat), "bearing #{bearing} latitude"
      assert box.longitudes.cover?(lng), "bearing #{bearing} longitude"
    end
  end
end
