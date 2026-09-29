module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_user!, only: :destroy

      def create
        user = User.authenticate_by(email: params.require(:email), password: params.require(:password))
        if user
          render json: { token: ApiToken.issue!(user), user: UserSerializer.render(user, include_private: true) },
                 status: :created
        else
          render json: { error: "Invalid email or password." }, status: :unauthorized
        end
      end

      def destroy
        current_api_token.destroy!
        head :no_content
      end
    end
  end
end
