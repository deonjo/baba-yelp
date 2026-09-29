module Api
  module V1
    # Address <-> coordinates lookups used by the app to pick a search location
    # ("Fremont, CA") and to prefill a new restaurant's address.
    class GeocodingController < BaseController
      rescue_from Geocoding::Unavailable do
        render json: { error: "Location lookup is unavailable right now. Please try again." },
               status: :service_unavailable
      end

      def search
        query = params.require(:q).to_s.squish
        raise BadRequest, "q must be at least 2 characters." if query.length < 2

        render json: { results: Geocoding.search(query).map(&:to_h) }
      end

      def reverse
        latitude, longitude = coordinate_params(required: true)
        place = Geocoding.reverse(latitude, longitude)
        return render_not_found unless place

        render json: { result: place.to_h }
      end
    end
  end
end
