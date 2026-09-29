module Api
  module V1
    class MeController < BaseController
      before_action :authenticate_user!

      def show
        render json: { user: UserSerializer.render(current_user, include_private: true) }
      end

      # Account deletion (required by the App Store for apps with sign-up).
      # Removes the user's reviews; restaurants and dishes they added remain.
      def destroy
        unless current_user.authenticate(params.require(:password))
          return render json: { error: "Incorrect password." }, status: :forbidden
        end

        current_user.destroy!
        head :no_content
      end

      def reviews
        scope = current_user.reviews.includes(:user, restaurant_dish: [ :restaurant, :dish ]).newest_first
        if params[:restaurant_id].present?
          scope = scope.where(restaurant_dish: RestaurantDish.where(restaurant_id: params[:restaurant_id]))
        end
        reviews, meta = paginate(scope)
        render json: {
          reviews: reviews.map { |review| ReviewSerializer.render(review, include_context: true) },
          meta: meta
        }
      end
    end
  end
end
