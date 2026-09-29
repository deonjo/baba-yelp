require "test_helper"

class GeocodingApiTest < ActionDispatch::IntegrationTest
  test "looks up places by name" do
    Geocoder::Lookup::Test.add_stub("Fremont, CA", [
      { "coordinates" => [ 37.5482697, -121.9885719 ], "address" => "Fremont, Alameda County, California, United States",
        "city" => "Fremont", "state_code" => "CA" }
    ])

    get "/api/v1/geocode", params: { q: " Fremont,  CA " }

    assert_response :ok
    assert_equal [ { "label" => "Fremont, CA", "address" => "Fremont, Alameda County, California, United States", "street" => nil,
                     "city" => "Fremont", "state" => "CA", "zip_code" => nil, "latitude" => 37.5482697, "longitude" => -121.9885719 } ],
                 json["results"]
  end

  test "requires a query of at least two characters" do
    get "/api/v1/geocode", params: { q: "F" }
    assert_response :bad_request

    get "/api/v1/geocode"
    assert_response :bad_request
  end

  test "reports when the lookup service is unavailable" do
    Geocoder.stub(:search, ->(*) { raise Geocoder::OverQueryLimitError }) do
      get "/api/v1/geocode", params: { q: "Fremont, CA" }
    end

    assert_response :service_unavailable
    assert_match(/unavailable/, json["error"])
  end

  test "reverse geocodes coordinates into an address" do
    Geocoder::Lookup::Test.add_stub([ 37.5508, -121.9861 ], [
      { "coordinates" => [ 37.5508, -121.9861 ], "street_address" => "39170 State St", "city" => "Fremont", "state_code" => "CA", "postal_code" => "94538" }
    ])

    get "/api/v1/geocode/reverse", params: { lat: 37.5508, lng: -121.9861 }

    assert_response :ok
    assert_equal [ "39170 State St", "Fremont", "CA", "94538" ], json["result"].values_at("street", "city", "state", "zip_code")
  end

  test "reverse geocoding needs coordinates and may find nothing" do
    get "/api/v1/geocode/reverse"
    assert_response :bad_request

    Geocoder::Lookup::Test.add_stub([ 0.0, 0.0 ], [])
    get "/api/v1/geocode/reverse", params: { lat: 0, lng: 0 }
    assert_response :not_found
  end
end
