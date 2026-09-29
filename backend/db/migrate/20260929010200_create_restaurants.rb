class CreateRestaurants < ActiveRecord::Migration[8.1]
  def change
    create_table :restaurants do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip_code
      t.string :phone
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :restaurant_dishes_count, null: false, default: 0
      t.timestamps
    end
    add_index :restaurants, [ :latitude, :longitude ]
    add_index :restaurants, :name
  end
end
