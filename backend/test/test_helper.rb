ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"

# rails/test_help opens a connection to check the schema; close it so parallel
# test workers don't inherit (and have to discard) a writable SQLite handle.
ActiveRecord::Base.connection_handler.clear_all_connections!(:all)

# Never call a real geocoding service from tests; stub lookups per test.
Geocoder.configure(lookup: :test)

# The center of Fremont, CA: the search location used throughout the tests.
FREMONT = [ 37.5483, -121.9886 ].freeze

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    setup { Geocoder::Lookup::Test.reset }

    # Adds one review per rating, each from a new user, and returns the
    # restaurant dish with its refreshed aggregates.
    def add_reviews(restaurant_dish, *ratings)
      ratings.each do |rating|
        user = User.create!(name: "Reviewer", email: "reviewer-#{SecureRandom.hex(6)}@example.com", password: "password123")
        Review.create!(user: user, restaurant_dish: restaurant_dish, rating: rating)
      end
      restaurant_dish.reload
    end
  end
end

module ActionDispatch
  class IntegrationTest
    def auth_headers(user)
      { "Authorization" => "Bearer #{ApiToken.issue!(user)}" }
    end

    def json
      response.parsed_body
    end
  end
end
