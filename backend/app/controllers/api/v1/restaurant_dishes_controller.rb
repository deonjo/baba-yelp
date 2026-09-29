module Api
  module V1
    class RestaurantDishesController < BaseController
      before_action :authenticate_user!, only: :create

      def show
        restaurant_dish = RestaurantDish.includes(:restaurant, dish: :cuisine).find(params[:id])
        my_review = restaurant_dish.reviews.includes(:user).find_by(user: current_user) if current_user

        render json: {
          restaurant_dish: RestaurantDishSerializer.render(restaurant_dish, include_restaurant: true).merge(
            rating_distribution: restaurant_dish.rating_distribution,
            my_review: (ReviewSerializer.render(my_review) if my_review)
          )
        }
      end

      # Adds a dish to a restaurant's menu. Idempotent: returns the existing link
      # (200) if the restaurant already serves the dish, otherwise creates it (201).
      def create
        restaurant = Restaurant.find(params.require(:restaurant_id))
        dish = Dish.find(params.require(:dish_id))
        restaurant_dish = restaurant.serve!(dish, added_by: current_user)

        render json: { restaurant_dish: RestaurantDishSerializer.render(restaurant_dish, include_restaurant: true) },
               status: restaurant_dish.previously_new_record? ? :created : :ok
      end
    end
  end
end
