class CreateRestaurantDishesAndReviews < ActiveRecord::Migration[8.1]
  def change
    # A dish as served by a specific restaurant. This is what customers rate.
    create_table :restaurant_dishes do |t|
      t.references :restaurant, null: false, foreign_key: true, index: false
      t.references :dish, null: false, foreign_key: true
      t.references :added_by, foreign_key: { to_table: :users, on_delete: :nullify }
      # Cached from reviews; refreshed whenever a review is saved or destroyed.
      t.integer :reviews_count, null: false, default: 0
      t.float :average_rating
      t.timestamps
    end
    add_index :restaurant_dishes, [ :restaurant_id, :dish_id ], unique: true

    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.references :restaurant_dish, null: false, foreign_key: true, index: false
      t.integer :rating, null: false
      t.text :body
      t.timestamps
      t.check_constraint "rating BETWEEN 1 AND 5", name: "reviews_rating_between_1_and_5"
    end
    add_index :reviews, [ :user_id, :restaurant_dish_id ], unique: true
    add_index :reviews, [ :restaurant_dish_id, :created_at ]
  end
end
