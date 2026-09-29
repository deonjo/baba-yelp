require "test_helper"

class ApiTokenTest < ActiveSupport::TestCase
  test "issues a random token and stores only its digest" do
    raw_token = ApiToken.issue!(users(:alice))
    token = ApiToken.last

    assert_operator raw_token.length, :>=, 32
    assert_not_equal raw_token, token.token_digest
    assert_equal ApiToken.digest(raw_token), token.token_digest
  end

  test "authenticates a raw token and records when it was used" do
    raw_token = ApiToken.issue!(users(:alice))

    token = ApiToken.authenticate(raw_token)
    assert_equal users(:alice), token.user
    assert_not_nil token.last_used_at
  end

  test "rejects unknown and blank tokens" do
    assert_nil ApiToken.authenticate("nope")
    assert_nil ApiToken.authenticate("")
    assert_nil ApiToken.authenticate(nil)
  end
end
