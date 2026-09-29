class UserSerializer
  def self.render(user, include_private: false)
    json = { id: user.id, name: user.name }
    if include_private
      json[:email] = user.email
      json[:reviews_count] = user.reviews.count
      json[:created_at] = user.created_at.utc.iso8601
    end
    json
  end
end
