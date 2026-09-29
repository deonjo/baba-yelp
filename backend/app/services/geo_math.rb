module GeoMath
  EARTH_RADIUS_MILES = 3958.8
  # Slightly below the true ~69 miles per degree, so bounding boxes err on the large side.
  MILES_PER_DEGREE = 68.7

  BoundingBox = Data.define(:latitudes, :longitudes)

  module_function

  # Great-circle (haversine) distance in miles.
  def distance_miles(lat1, lng1, lat2, lng2)
    d_lat = radians(lat2 - lat1)
    d_lng = radians(lng2 - lng1)
    a = Math.sin(d_lat / 2)**2 +
        Math.cos(radians(lat1)) * Math.cos(radians(lat2)) * Math.sin(d_lng / 2)**2
    2 * EARTH_RADIUS_MILES * Math.asin(Math.sqrt(a).clamp(0.0, 1.0))
  end

  # Latitude/longitude ranges that contain every point within radius_miles, used
  # to pre-filter rows in SQL before computing exact distances.
  def bounding_box(latitude, longitude, radius_miles)
    d_lat = radius_miles / MILES_PER_DEGREE
    d_lng = radius_miles / (MILES_PER_DEGREE * [ Math.cos(radians(latitude)).abs, 0.01 ].max)
    BoundingBox.new(
      latitudes: (latitude - d_lat)..(latitude + d_lat),
      longitudes: (longitude - d_lng)..(longitude + d_lng)
    )
  end

  def radians(degrees)
    degrees * Math::PI / 180
  end
end
