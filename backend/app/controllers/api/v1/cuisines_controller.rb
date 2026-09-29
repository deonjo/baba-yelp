module Api
  module V1
    class CuisinesController < BaseController
      def index
        render json: { cuisines: Cuisine.ordered.map { |cuisine| CuisineSerializer.render(cuisine) } }
      end
    end
  end
end
