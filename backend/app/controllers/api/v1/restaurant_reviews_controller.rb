module Api
  module V1
    # Reviews one or more dishes eaten at a restaurant in a single request:
    #
    #   POST /api/v1/restaurants/:restaurant_id/reviews
    #   { "reviews": [ { "dish_id": 1, "rating": 5, "body": "..." }, ... ] }
    #
    # Dishes not yet on the restaurant's menu are linked to it. Re-reviewing a
    # dish replaces your previous review. All reviews are saved, or none are.
    class RestaurantReviewsController < BaseController
      MAX_REVIEWS = 10

      before_action :authenticate_user!

      def create
        restaurant = Restaurant.find(params[:restaurant_id])
        entries = review_entries
        dishes = Dish.where(id: entries.map { |entry| entry[:dish_id] }).index_by(&:id)
        reviews = []
        errors = []

        ActiveRecord::Base.transaction do
          entries.each do |entry|
            dish = dishes[entry[:dish_id].to_i]
            unless dish
              errors << { dish_id: entry[:dish_id], errors: [ "Dish not found" ] }
              next
            end

            review = restaurant.serve!(dish, added_by: current_user).reviews.find_or_initialize_by(user: current_user)
            review.assign_attributes(rating: entry[:rating], body: entry[:body])
            if review.save
              reviews << review
            else
              errors << { dish_id: dish.id, dish_name: dish.name, errors: review.errors.full_messages }
            end
          end
          raise ActiveRecord::Rollback if errors.any?
        end

        if errors.any?
          render json: { error: "Your reviews could not be saved.", errors: errors }, status: :unprocessable_content
        else
          created = reviews.any? { |review| review.previously_new_record? }
          render json: { reviews: reviews.map { |review| ReviewSerializer.render(review, include_context: true) } },
                 status: created ? :created : :ok
        end
      end

      private

      def review_entries
        raw = params.require(:reviews)
        raise BadRequest, "reviews must be a list." unless raw.is_a?(Array)
        raise BadRequest, "You can review at most #{MAX_REVIEWS} dishes at once." if raw.size > MAX_REVIEWS

        entries = raw.map do |entry|
          raise BadRequest, "Each review must be an object." unless entry.is_a?(ActionController::Parameters)

          entry.permit(:dish_id, :rating, :body)
        end
        dish_ids = entries.map { |entry| entry[:dish_id].to_s }
        raise BadRequest, "Each review needs a dish_id." if dish_ids.any?(&:blank?)
        raise BadRequest, "Each dish can only be reviewed once per submission." if dish_ids.uniq.size < dish_ids.size

        entries
      end
    end
  end
end
