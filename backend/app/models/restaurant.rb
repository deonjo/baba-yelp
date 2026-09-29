class Restaurant < ApplicationRecord
  # Restaurants with the same name this close together are treated as duplicates.
  DUPLICATE_RADIUS_MILES = 0.1

  belongs_to :created_by, class_name: "User", optional: true
  has_many :restaurant_dishes, dependent: :destroy
  has_many :dishes, through: :restaurant_dishes

  normalizes :name, :address, :city, with: ->(value) { value.squish }
  normalizes :state, with: ->(value) { value.squish.upcase }
  normalizes :zip_code, :phone, with: ->(value) { value.squish.presence }

  before_validation :geocode_address, if: :needs_geocoding?

  validates :name, presence: true, length: { maximum: 100 }
  validates :address, presence: true, length: { maximum: 200 }
  validates :city, presence: true, length: { maximum: 100 }
  validates :state, presence: true, length: { maximum: 50 }
  validates :zip_code, length: { maximum: 20 }
  validates :phone, length: { maximum: 30 }
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :coordinates_present

  def full_address
    [ address, city, [ state, zip_code ].compact_blank.join(" ") ].compact_blank.join(", ")
  end

  def distance_from(latitude, longitude)
    GeoMath.distance_miles(latitude, longitude, self.latitude, self.longitude)
  end

  # Links the dish to this restaurant's menu (idempotent) and returns the link.
  def serve!(dish, added_by: nil)
    restaurant_dishes.find_or_create_by!(dish: dish) { |restaurant_dish| restaurant_dish.added_by = added_by }
  rescue ActiveRecord::RecordNotUnique
    restaurant_dishes.find_by!(dish: dish)
  end

  # An existing restaurant with the same name at (almost) the same location.
  def nearby_duplicate
    return if latitude.blank? || longitude.blank? || name_key.blank?

    box = GeoMath.bounding_box(latitude, longitude, DUPLICATE_RADIUS_MILES)
    Restaurant.where(latitude: box.latitudes, longitude: box.longitudes).where.not(id: id).find do |other|
      other.name_key == name_key && other.distance_from(latitude, longitude) <= DUPLICATE_RADIUS_MILES
    end
  end

  def name_key
    name.to_s.downcase.gsub(/[^[:alnum:]]/, "")
  end

  private

  def needs_geocoding?
    (latitude.blank? || longitude.blank?) && address.present? && city.present? && state.present?
  end

  def geocode_address
    place = Geocoding.search(full_address, limit: 1).first
    if place
      self.latitude = place.latitude
      self.longitude = place.longitude
    else
      @geocoding_error = "could not be found on the map. Check it, or use your current location."
    end
  rescue Geocoding::Unavailable
    @geocoding_error = "could not be looked up right now. Try again, or use your current location."
  end

  def coordinates_present
    return if latitude.present? && longitude.present?

    errors.add(:address, @geocoding_error || "needs a map location (latitude and longitude)")
  end
end
