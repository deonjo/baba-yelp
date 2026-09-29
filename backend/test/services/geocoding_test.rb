require "test_helper"

class GeocodingTest < ActiveSupport::TestCase
  test "turns geocoder results into places with short state codes" do
    Geocoder::Lookup::Test.add_stub("Fremont, CA", [
      {
        "coordinates" => [ 37.5482697, -121.9885719 ],
        "address" => "Fremont, Alameda County, California, United States",
        "city" => "Fremont",
        "state" => "California",
        "state_code" => "CA",
        "postal_code" => "94538"
      }
    ])

    place = Geocoding.search("Fremont, CA").first
    assert_equal "Fremont, CA", place.label
    assert_equal "Fremont", place.city
    assert_equal "CA", place.state
    assert_equal "94538", place.zip_code
    assert_in_delta 37.5482697, place.latitude
    assert_in_delta(-121.9885719, place.longitude)
  end

  test "reads the ISO state code and street from Nominatim-style address details" do
    Geocoder::Lookup::Test.add_stub([ 37.5508, -121.9861 ], [
      {
        "coordinates" => [ 37.5508, -121.9861 ],
        "address" => { "house_number" => "39170", "road" => "State Street", "city" => "Fremont", "state" => "California", "ISO3166-2-lvl4" => "US-CA" },
        "street_address" => "39170 State Street",
        "city" => "Fremont",
        "state" => "California"
      }
    ])

    place = Geocoding.reverse(37.5508, -121.9861)
    assert_equal "CA", place.state
    assert_equal "39170 State Street", place.street
    assert_equal "39170 State Street, Fremont, CA", place.label
  end

  test "skips results without coordinates" do
    Geocoder::Lookup::Test.add_stub("nowhere", [ { "address" => "Nowhere" } ])
    assert_empty Geocoding.search("nowhere")
  end

  test "raises Unavailable when the provider fails" do
    [ Geocoder::ServiceUnavailable, Geocoder::OverQueryLimitError, SocketError, Timeout::Error ].each do |error|
      Geocoder.stub(:search, ->(*) { raise error }) do
        assert_raises(Geocoding::Unavailable) { Geocoding.search("Fremont, CA") }
      end
    end
  end
end
