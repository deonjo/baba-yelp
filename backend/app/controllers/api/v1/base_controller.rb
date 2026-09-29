module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      class BadRequest < StandardError; end

      DEFAULT_PER_PAGE = 20
      MAX_PER_PAGE = 50

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: ->(error) { render_validation_errors(error.record) }
      rescue_from ActionController::ParameterMissing, BadRequest, with: :render_bad_request

      private

      def current_user
        return @current_user if defined?(@current_user)

        @current_api_token = authenticate_with_http_token { |token, _options| ApiToken.authenticate(token) }
        @current_user = @current_api_token&.user
      end

      def current_api_token
        current_user
        @current_api_token
      end

      def authenticate_user!
        return if current_user

        headers["WWW-Authenticate"] = %(Bearer realm="Baba Yelp")
        render json: { error: "Please sign in to continue." }, status: :unauthorized
      end

      def render_not_found(_error = nil)
        render json: { error: "Not found." }, status: :not_found
      end

      def render_bad_request(error)
        render json: { error: error.message }, status: :bad_request
      end

      def render_validation_errors(record)
        render json: { error: record.errors.full_messages.to_sentence, errors: record.errors.to_hash },
               status: :unprocessable_content
      end

      def paginate(scope, **options)
        page, per_page = pagination_params(**options)
        total_count = scope.count
        records = scope.offset((page - 1) * per_page).limit(per_page).to_a
        [ records, pagination_meta(page, per_page, total_count) ]
      end

      def paginate_array(array, **options)
        page, per_page = pagination_params(**options)
        records = array.slice((page - 1) * per_page, per_page) || []
        [ records, pagination_meta(page, per_page, array.size) ]
      end

      def pagination_params(default_per_page: DEFAULT_PER_PAGE, max_per_page: MAX_PER_PAGE)
        page = [ params[:page].to_i, 1 ].max
        per_page = (params[:per_page].presence || default_per_page).to_i.clamp(1, max_per_page)
        [ page, per_page ]
      end

      def pagination_meta(page, per_page, total_count)
        { page: page, per_page: per_page, total_count: total_count, total_pages: (total_count.to_f / per_page).ceil }
      end

      # [latitude, longitude] from the lat/lng query params, or nil when absent.
      def coordinate_params(required: false)
        lat = params[:lat].presence
        lng = params[:lng].presence
        if lat.nil? && lng.nil?
          raise BadRequest, "lat and lng are required." if required

          return
        end
        raise BadRequest, "lat and lng must be given together." if lat.nil? || lng.nil?

        latitude = Float(lat, exception: false)
        longitude = Float(lng, exception: false)
        raise BadRequest, "lat must be a number between -90 and 90." unless latitude&.between?(-90, 90)
        raise BadRequest, "lng must be a number between -180 and 180." unless longitude&.between?(-180, 180)

        [ latitude, longitude ]
      end
    end
  end
end
