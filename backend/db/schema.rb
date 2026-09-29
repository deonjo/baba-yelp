# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_29_010300) do
  create_table "api_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "last_used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_api_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_api_tokens_on_user_id"
  end

  create_table "cuisines", force: :cascade do |t|
    t.string "name", null: false
    t.string "emoji"
    t.integer "dishes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_cuisines_on_name", unique: true
  end

  create_table "dishes", force: :cascade do |t|
    t.integer "cuisine_id", null: false
    t.string "name", null: false
    t.string "aliases"
    t.text "description"
    t.integer "created_by_id"
    t.integer "restaurant_dishes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_dishes_on_created_by_id"
    t.index ["cuisine_id", "name"], name: "index_dishes_on_cuisine_id_and_name", unique: true
    t.index ["name"], name: "index_dishes_on_name"
  end

  create_table "restaurant_dishes", force: :cascade do |t|
    t.integer "restaurant_id", null: false
    t.integer "dish_id", null: false
    t.integer "added_by_id"
    t.integer "reviews_count", default: 0, null: false
    t.float "average_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["added_by_id"], name: "index_restaurant_dishes_on_added_by_id"
    t.index ["dish_id"], name: "index_restaurant_dishes_on_dish_id"
    t.index ["restaurant_id", "dish_id"], name: "index_restaurant_dishes_on_restaurant_id_and_dish_id", unique: true
  end

  create_table "restaurants", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.string "city", null: false
    t.string "state", null: false
    t.string "zip_code"
    t.string "phone"
    t.float "latitude", null: false
    t.float "longitude", null: false
    t.integer "created_by_id"
    t.integer "restaurant_dishes_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_id"], name: "index_restaurants_on_created_by_id"
    t.index ["latitude", "longitude"], name: "index_restaurants_on_latitude_and_longitude"
    t.index ["name"], name: "index_restaurants_on_name"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "restaurant_dish_id", null: false
    t.integer "rating", null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restaurant_dish_id", "created_at"], name: "index_reviews_on_restaurant_dish_id_and_created_at"
    t.index ["user_id", "restaurant_dish_id"], name: "index_reviews_on_user_id_and_restaurant_dish_id", unique: true
    t.check_constraint "rating BETWEEN 1 AND 5", name: "reviews_rating_between_1_and_5"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "api_tokens", "users", on_delete: :cascade
  add_foreign_key "dishes", "cuisines"
  add_foreign_key "dishes", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "restaurant_dishes", "dishes"
  add_foreign_key "restaurant_dishes", "restaurants"
  add_foreign_key "restaurant_dishes", "users", column: "added_by_id", on_delete: :nullify
  add_foreign_key "restaurants", "users", column: "created_by_id", on_delete: :nullify
  add_foreign_key "reviews", "restaurant_dishes"
  add_foreign_key "reviews", "users"
end
