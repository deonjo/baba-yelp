module Api
  module V1
    class UsersController < BaseController
      def create
        user = User.create!(params.require(:user).permit(:name, :email, :password))
        render json: { token: ApiToken.issue!(user), user: UserSerializer.render(user, include_private: true) },
               status: :created
      end
    end
  end
end
