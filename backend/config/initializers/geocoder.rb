# Geocoding (address <-> coordinates) defaults to OpenStreetMap's free Nominatim
# service, which needs no API key but allows at most ~1 request per second and
# asks callers to identify themselves. For production traffic, point this at a
# commercial provider, e.g. GEOCODER_LOOKUP=google GEOCODER_API_KEY=...
# See https://github.com/alexreisner/geocoder#geocoding-service-lookup-configuration
Geocoder.configure(
  lookup: ENV.fetch("GEOCODER_LOOKUP", "nominatim").to_sym,
  api_key: ENV["GEOCODER_API_KEY"],
  timeout: 5,
  units: :mi,
  http_headers: { "User-Agent" => ENV.fetch("GEOCODER_USER_AGENT", "BabaYelp/1.0 (https://github.com/deonjo/baba-yelp)") },
  cache: Rails.cache,
  # Raise instead of silently returning no results, so "service down" can be
  # told apart from "address not found".
  always_raise: :all
)
