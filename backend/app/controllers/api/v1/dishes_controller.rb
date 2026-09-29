module Api
  module V1
    class DishesController < BaseController
      before_action :authenticate_user!, only: :create

      def index
        scope = Dish.includes(:cuisine)
        scope = scope.where(cuisine_id: params[:cuisine_id]) if params[:cuisine_id].present?
        scope = params[:q].present? ? scope.search(params[:q]) : scope.ordered
        dishes, meta = paginate(scope, default_per_page: 50, max_per_page: 100)
        render json: { dishes: dishes.map { |dish| DishSerializer.render(dish) }, meta: meta }
      end

      def show
        render json: { dish: DishSerializer.render(Dish.includes(:cuisine).find(params[:id])) }
      end

      def create
        dish = Dish.create!(params.require(:dish).permit(:name, :cuisine_id, :aliases, :description)
                                  .merge(created_by: current_user))
        render json: { dish: DishSerializer.render(dish) }, status: :created
      end
    end
  end
end
