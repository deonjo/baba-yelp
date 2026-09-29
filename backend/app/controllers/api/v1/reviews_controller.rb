module Api
  module V1
    class ReviewsController < BaseController
      before_action :authenticate_user!, only: [ :update, :destroy ]

      def index
        restaurant_dish = RestaurantDish.find(params[:restaurant_dish_id])
        reviews, meta = paginate(restaurant_dish.reviews.includes(:user).newest_first)
        render json: { reviews: reviews.map { |review| ReviewSerializer.render(review) }, meta: meta }
      end

      def update
        review = current_user.reviews.find(params[:id])
        review.update!(params.require(:review).permit(:rating, :body))
        render json: { review: ReviewSerializer.render(review, include_context: true) }
      end

      def destroy
        current_user.reviews.find(params[:id]).destroy!
        head :no_content
      end
    end
  end
end
