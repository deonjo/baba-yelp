require "test_helper"

class DishTest < ActiveSupport::TestCase
  test "names are unique within a cuisine, ignoring case" do
    duplicate = Dish.new(cuisine: cuisines(:thai), name: "pad thai")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"

    assert Dish.new(cuisine: cuisines(:american), name: "Pad Thai").valid?
  end

  test "normalizes aliases into a clean comma-separated list" do
    dish = Dish.create!(cuisine: cuisines(:thai), name: "Khao Soi", aliases: " Kao Soi ,, Khao  Soy ")
    assert_equal "Kao Soi, Khao Soy", dish.aliases
    assert_equal [ "Kao Soi", "Khao Soy" ], dish.alias_list
  end

  test "search matches names, aliases and cuisines with name prefix matches first" do
    assert_equal [ "Hamburger" ], Dish.search("burger").map(&:name)
    assert_equal [ "Tom Yum Soup" ], Dish.search("tom yam").map(&:name)
    assert_equal "Pad Thai", Dish.search("pad").first.name

    thai = Dish.search("thai").map(&:name)
    assert_equal "Pad Thai", thai.first, "name matches rank above cuisine-only matches"
    assert_equal [ "Green Curry", "Pad Thai", "Tom Yum Soup" ], thai.sort
  end

  test "search treats LIKE wildcards literally" do
    assert_empty Dish.search("%")
    assert_empty Dish.search("_")
  end
end
