# Bearer token used by the mobile app. Only a SHA-256 digest of the token is
# stored, so a leaked database does not leak usable credentials.
class ApiToken < ApplicationRecord
  TOUCH_INTERVAL = 1.hour

  belongs_to :user

  def self.digest(raw_token)
    OpenSSL::Digest::SHA256.hexdigest(raw_token)
  end

  # Creates a token for the user and returns the raw value (shown only once).
  def self.issue!(user)
    raw_token = SecureRandom.base58(32)
    create!(user: user, token_digest: digest(raw_token))
    raw_token
  end

  def self.authenticate(raw_token)
    return if raw_token.blank?

    find_by(token_digest: digest(raw_token))&.tap(&:touch_last_used)
  end

  def touch_last_used
    return if last_used_at && last_used_at > TOUCH_INTERVAL.ago

    update_column(:last_used_at, Time.current)
  end
end
