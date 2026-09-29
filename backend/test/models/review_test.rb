require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  test "rating must be a whole number from 1 to 5" do
    [ 0, 6, 4.5, nil ].each do |rating|
      review = Review.new(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: rating)
      assert_not review.valid?, "#{rating.inspect} should be invalid"
    end
    assert Review.new(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 5).valid?
  end

  test "a user reviews each restaurant dish only once" do
    Review.create!(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 5)
    second = Review.new(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 3)
    assert_not second.valid?

    assert Review.new(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_tom_yum), rating: 3).valid?
  end

  test "blank bodies are stored as nil" do
    review = Review.create!(user: users(:alice), restaurant_dish: restaurant_dishes(:orchid_pad_thai), rating: 4, body: "   ")
    assert_nil review.body
  end

  test "keeps the restaurant dish's rating and review count up to date" do
    restaurant_dish = restaurant_dishes(:orchid_pad_thai)

    first = Review.create!(user: users(:alice), restaurant_dish: restaurant_dish, rating: 5)
    Review.create!(user: users(:bob), restaurant_dish: restaurant_dish, rating: 2)
    assert_equal [ 2, 3.5 ], restaurant_dish.reload.values_at(:reviews_count, :average_rating)

    first.update!(rating: 3)
    assert_equal [ 2, 2.5 ], restaurant_dish.reload.values_at(:reviews_count, :average_rating)

    first.destroy!
    assert_equal [ 1, 2.0 ], restaurant_dish.reload.values_at(:reviews_count, :average_rating)
  end

  test "rating distribution counts reviews per star" do
    restaurant_dish = add_reviews(restaurant_dishes(:orchid_pad_thai), 5, 5, 4, 1)
    assert_equal({ 5 => 2, 4 => 1, 3 => 0, 2 => 0, 1 => 1 }, restaurant_dish.rating_distribution)
  end
end
