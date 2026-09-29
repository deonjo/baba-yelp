class CreateCuisinesAndDishes < ActiveRecord::Migration[8.1]
  def change
    create_table :cuisines do |t|
      t.string :name, null: false
      t.string :emoji
      t.integer :dishes_count, null: false, default: 0
      t.timestamps
    end
    add_index :cuisines, :name, unique: true

    create_table :dishes do |t|
      t.references :cuisine, null: false, foreign_key: true, index: false
      t.string :name, null: false
      # Comma-separated alternative names ("Phat Thai, Pad Thai Noodles") that search also matches.
      t.string :aliases
      t.text :description
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :restaurant_dishes_count, null: false, default: 0
      t.timestamps
    end
    add_index :dishes, [ :cuisine_id, :name ], unique: true
    add_index :dishes, :name
  end
end
