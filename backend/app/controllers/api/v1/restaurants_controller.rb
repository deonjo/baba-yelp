module Api
  module V1
    class RestaurantsController < BaseController
      before_action :authenticate_user!, only: :create

      # Search. See RestaurantSearch for filters and sort order.
      def index
        latitude, longitude = coordinate_params
        search = RestaurantSearch.new(
          query: params[:q],
          dish_ids: dish_ids_param,
          latitude: latitude,
          longitude: longitude,
          radius: params[:radius],
          sort: params[:sort],
          match: params[:match],
          min_rating: params[:min_rating]
        )
        results, meta = paginate_array(search.results)
        render json: {
          restaurants: results.map { |result| RestaurantSerializer.search_result(result) },
          meta: meta.merge(search.applied_filters)
        }
      end

      def show
        restaurant = Restaurant.find(params[:id])
        latitude, longitude = coordinate_params
        restaurant_dishes = restaurant.restaurant_dishes.includes(dish: :cuisine).best_first.to_a
        rating, reviews_count = RestaurantDish.combined_rating(restaurant_dishes)
        distance = restaurant.distance_from(latitude, longitude) if latitude

        render json: {
          restaurant: RestaurantSerializer.render(restaurant, distance_miles: distance).merge(
            rating: rating&.round(1),
            reviews_count: reviews_count,
            dishes: restaurant_dishes.map { |restaurant_dish| RestaurantDishSerializer.render(restaurant_dish) }
          )
        }
      end

      def create
        restaurant = Restaurant.new(restaurant_params.merge(created_by: current_user))
        return render_validation_errors(restaurant) unless restaurant.valid?

        if (existing = restaurant.nearby_duplicate)
          return render json: {
            error: "#{existing.name} is already listed at #{existing.full_address}.",
            restaurant: RestaurantSerializer.render(existing)
          }, status: :conflict
        end

        restaurant.save!
        render json: { restaurant: RestaurantSerializer.render(restaurant) }, status: :created
      end

      private

      def restaurant_params
        params.require(:restaurant).permit(:name, :address, :city, :state, :zip_code, :phone, :latitude, :longitude)
      end

      # Accepts dish_ids[]=1&dish_ids[]=2 or dish_ids=1,2
      def dish_ids_param
        raw = params[:dish_ids]
        values = raw.is_a?(String) ? raw.split(",") : Array(raw)
        ids = values.map { |value| Integer(value.to_s.strip, exception: false) }
        raise BadRequest, "dish_ids must be a list of dish ids." if ids.any? { |id| id.nil? || id <= 0 }
        raise BadRequest, "Search for at most #{RestaurantSearch::MAX_DISHES} dishes at a time." if ids.uniq.size > RestaurantSearch::MAX_DISHES

        ids.uniq
      end
    end
  end
end
