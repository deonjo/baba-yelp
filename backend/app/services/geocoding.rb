# Thin wrapper around the geocoder gem that turns provider-specific results into
# simple Place values and provider failures into Geocoding::Unavailable.
module Geocoding
  class Unavailable < StandardError; end

  Place = Data.define(:label, :address, :street, :city, :state, :zip_code, :latitude, :longitude)

  PROVIDER_ERRORS = [
    Geocoder::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError
  ].freeze

  module_function

  def search(query, limit: 5)
    results = lookup { Geocoder.search(query, params: { limit: limit }) }
    results.filter_map { |result| to_place(result) }.first(limit)
  end

  def reverse(latitude, longitude)
    lookup { Geocoder.search([ latitude, longitude ]) }.filter_map { |result| to_place(result) }.first
  end

  def lookup
    yield
  rescue *PROVIDER_ERRORS => e
    Rails.logger.warn("Geocoding failed: #{e.class}: #{e.message}")
    raise Unavailable, e.message
  end

  def to_place(result)
    latitude, longitude = result.coordinates
    return if latitude.nil? || longitude.nil?

    street = street_line(result)
    city = value(result, :city)
    state = state_code(result)
    label = [ street, city, state ].compact_blank.join(", ").presence ||
            result.address.to_s.split(",").first(3).map(&:strip).join(", ")

    Place.new(
      label: label,
      address: result.address,
      street: street,
      city: city,
      state: state,
      zip_code: value(result, :postal_code),
      latitude: latitude.to_f,
      longitude: longitude.to_f
    )
  end

  def street_line(result)
    parts = [
      value(result, :house_number) || value(result, :street_number),
      value(result, :street) || value(result, :route)
    ].compact
    parts.any? ? parts.join(" ") : value(result, :street_address)
  end

  # Prefer the short ISO code ("CA") that Nominatim reports as "US-CA".
  def state_code(result)
    iso = result.data.dig("address", "ISO3166-2-lvl4") if result.data.is_a?(Hash) && result.data["address"].is_a?(Hash)
    return iso.split("-").last if iso.present?

    value(result, :state_code) || value(result, :state)
  end

  def value(result, attribute)
    result.public_send(attribute).presence if result.respond_to?(attribute)
  end
end
