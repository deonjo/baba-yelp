require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and name" do
    user = User.create!(name: "  Carol   Cho ", email: " Carol@Example.COM ", password: "password123")
    assert_equal "carol@example.com", user.email
    assert_equal "Carol Cho", user.name
  end

  test "email must be unique regardless of case" do
    user = User.new(name: "Imposter", email: "ALICE@example.com", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires a valid email and a password of at least 8 characters" do
    user = User.new(name: "Dan", email: "not-an-email", password: "short")
    assert_not user.valid?
    assert user.errors[:email].any?
    assert user.errors[:password].any?
  end

  test "authenticates by email and password" do
    assert_equal users(:alice), User.authenticate_by(email: "Alice@Example.com", password: "password123")
    assert_nil User.authenticate_by(email: "alice@example.com", password: "wrong-password")
  end
end
