# Sample data for development and demos: a catalog of iconic dishes, fictional
# restaurants around Fremont, CA (plus a few farther away to exercise the search
# radius) and reviews from demo users. Safe to run more than once.
#
#   bin/rails db:seed          # load
#   bin/rails db:reset         # wipe and reload
#
# Every demo account's password is "password123". Sign in as demo@example.com
# to write reviews of your own.

DEMO_PASSWORD = "password123".freeze

CATALOG = {
  [ "American", "🇺🇸" ] => {
    "Hamburger" => [ "Burger", "A grilled beef patty in a soft bun with lettuce, tomato, onion and pickles." ],
    "Cheeseburger" => [ "", "A hamburger crowned with melted cheese, usually American or cheddar." ],
    "Pizza" => [ "Italian pizza, Pepperoni pizza, New York-style pizza", "Italian-born and American-loved: a baked crust topped with tomato sauce, mozzarella and your favorite toppings." ],
    "Barbecue Ribs" => [ "BBQ ribs, Baby back ribs, Spare ribs", "Pork ribs slow-smoked until tender and finished with a tangy barbecue sauce." ],
    "Brisket" => [ "Smoked brisket, BBQ brisket", "Beef brisket smoked low and slow for hours until it pulls apart, Texas style." ],
    "Meatloaf" => [ "", "Seasoned ground beef baked in a loaf with a sweet tomato glaze. Classic diner comfort food." ],
    "Fried Chicken" => [ "Southern fried chicken", "Buttermilk-brined chicken dredged in seasoned flour and fried until crisp." ],
    "Hot Dog" => [ "Frankfurter, Frank", "A grilled sausage in a split bun with mustard, ketchup, relish or onions." ]
  },
  [ "Thai", "🇹🇭" ] => {
    "Basil Fried Rice with Pork" => [ "Pad Kra Pao Moo, Khao Pad Kra Pao, Holy basil pork", "Minced pork stir-fried with holy basil, chilies and garlic over rice, often topped with a fried egg." ],
    "Thai Fried Rice" => [ "Khao Pad", "Jasmine rice wok-fried with egg, onion and your choice of meat, served with lime and cucumber." ],
    "Pad Thai" => [ "Phat Thai", "Rice noodles stir-fried with tamarind, fish sauce, egg, tofu, bean sprouts and crushed peanuts." ],
    "Tom Yum Soup" => [ "Tom Yum Goong, Tom Yam", "Hot and sour soup with lemongrass, galangal, kaffir lime leaves, chilies and shrimp." ],
    "Green Curry" => [ "Gaeng Keow Wan", "Coconut-milk curry with green chili paste, Thai eggplant and sweet basil." ],
    "Pad See Ew" => [ "", "Wide rice noodles stir-fried with dark soy sauce, egg and Chinese broccoli." ],
    "Tom Kha Gai" => [ "Coconut chicken soup", "Creamy coconut soup with chicken, galangal and lemongrass." ],
    "Papaya Salad" => [ "Som Tum", "Shredded green papaya pounded with lime, fish sauce, chilies, tomatoes and peanuts." ],
    "Khao Soi" => [ "", "Northern Thai curry noodle soup topped with crispy fried egg noodles." ],
    "Mango Sticky Rice" => [ "", "Sweet coconut sticky rice served with ripe mango." ]
  },
  [ "Italian", "🇮🇹" ] => {
    "Spaghetti Carbonara" => [ "Carbonara", "Spaghetti tossed with egg, Pecorino Romano, guanciale and black pepper." ],
    "Lasagna" => [ "", "Layers of pasta, ragù, béchamel and cheese baked until bubbling." ],
    "Margherita Pizza" => [ "Neapolitan pizza", "Neapolitan pizza with San Marzano tomatoes, fresh mozzarella and basil." ],
    "Chicken Parmesan" => [ "Chicken Parm, Chicken Parmigiana", "Breaded chicken cutlet topped with marinara and melted mozzarella." ],
    "Mushroom Risotto" => [ "Risotto", "Creamy arborio rice slowly cooked with mushrooms and Parmesan." ]
  },
  [ "Mexican", "🇲🇽" ] => {
    "Tacos al Pastor" => [ "Al pastor", "Spit-roasted, chili-marinated pork on corn tortillas with pineapple, onion and cilantro." ],
    "Carne Asada Burrito" => [ "Burrito, Mission burrito", "A flour tortilla stuffed with grilled steak, rice, beans and salsa." ],
    "Enchiladas" => [ "", "Corn tortillas rolled around a filling and smothered in chili sauce and cheese." ],
    "Pozole" => [ "Posole", "Hominy stew with pork and red chile, topped with cabbage, radish and lime." ]
  },
  [ "Chinese", "🇨🇳" ] => {
    "Kung Pao Chicken" => [ "", "Diced chicken stir-fried with peanuts, dried chilies and Sichuan peppercorns." ],
    "Mapo Tofu" => [ "", "Silken tofu in a spicy, numbing sauce of chili bean paste and minced pork." ],
    "Xiao Long Bao" => [ "Soup dumplings", "Delicate pleated dumplings filled with pork and hot broth." ],
    "Chow Mein" => [ "", "Stir-fried egg noodles with vegetables and your choice of meat." ],
    "Peking Duck" => [ "", "Roast duck with lacquered, crisp skin, served with pancakes, scallions and hoisin." ]
  },
  [ "Japanese", "🇯🇵" ] => {
    "Tonkotsu Ramen" => [ "Ramen", "Wheat noodles in a rich pork-bone broth with chashu pork and a soft-boiled egg." ],
    "Sushi" => [ "Nigiri, Sushi rolls, Maki", "Vinegared rice with raw fish and other toppings." ],
    "Tonkatsu" => [ "Pork katsu", "Panko-breaded, deep-fried pork cutlet with tangy katsu sauce." ],
    "Shrimp Tempura" => [ "Tempura", "Shrimp and vegetables in a light, crisp batter." ]
  },
  [ "Vietnamese", "🇻🇳" ] => {
    "Pho" => [ "Phở, Pho Bo, Beef noodle soup", "Rice noodle soup in a fragrant beef broth with herbs, lime and thin-sliced beef." ],
    "Banh Mi" => [ "Bánh mì", "A crackly baguette sandwich with grilled pork, pâté, pickled vegetables and cilantro." ],
    "Bun Bo Hue" => [ "", "Spicy lemongrass beef noodle soup from Huế." ],
    "Spring Rolls" => [ "Goi Cuon, Fresh rolls, Summer rolls", "Rice paper rolls with shrimp, pork, herbs and vermicelli, served with peanut sauce." ]
  },
  [ "Indian", "🇮🇳" ] => {
    "Butter Chicken" => [ "Murgh Makhani", "Tandoori chicken simmered in a silky tomato, butter and cream sauce." ],
    "Chicken Tikka Masala" => [ "Tikka masala", "Grilled chicken pieces in a spiced, creamy tomato curry." ],
    "Chicken Biryani" => [ "Biryani", "Fragrant basmati rice layered with spiced chicken and saffron." ],
    "Masala Dosa" => [ "Dosa", "A crisp fermented rice-and-lentil crepe filled with spiced potatoes." ],
    "Palak Paneer" => [ "Saag Paneer", "Cubes of paneer cheese in a spiced spinach gravy." ]
  },
  [ "Korean", "🇰🇷" ] => {
    "Bibimbap" => [ "", "Rice topped with sautéed vegetables, beef, a fried egg and gochujang." ],
    "Korean Fried Chicken" => [ "Yangnyeom chicken", "Double-fried chicken with a shatteringly crisp crust, glazed or plain." ],
    "Bulgogi" => [ "", "Thin slices of soy-and-pear-marinated beef, grilled." ],
    "Kimchi Jjigae" => [ "Kimchi stew", "Hearty stew of aged kimchi, pork and tofu." ]
  },
  [ "Afghan", "🇦🇫" ] => {
    "Kabuli Pulao" => [ "Kabuli Palaw", "Afghanistan's national dish: rice with tender lamb, carrots and raisins." ],
    "Mantu" => [ "Mantoo", "Steamed beef dumplings topped with yogurt, lentils and dried mint." ],
    "Chapli Kebab" => [ "", "A spiced, flattened ground-beef kebab pan-fried until crisp." ],
    "Bolani" => [ "", "Thin flatbread stuffed with potatoes or leeks, pan-fried and served with yogurt." ]
  }
}.freeze

# Fictional restaurants. Each dish maps to the average rating its demo reviews
# should have (nil = on the menu but not reviewed yet).
RESTAURANTS = [
  # Thai places in and around Fremont, for "Pad Thai + Tom Yum Soup near Fremont".
  { name: "Thai Orchid Kitchen", address: "39170 State St", city: "Fremont", zip: "94538", phone: "(510) 555-0101", lat: 37.5508, lng: -121.9861,
    dishes: { "Pad Thai" => 4.6, "Tom Yum Soup" => 4.4, "Green Curry" => 4.5, "Basil Fried Rice with Pork" => 4.3, "Thai Fried Rice" => 4.0, "Mango Sticky Rice" => 4.7 } },
  { name: "Thai Basil Express", address: "39180 State St", city: "Fremont", zip: "94538", phone: "(510) 555-0102", lat: 37.5503, lng: -121.9868,
    dishes: { "Pad Thai" => 3.9, "Tom Yum Soup" => 3.6, "Basil Fried Rice with Pork" => 4.2, "Thai Fried Rice" => 3.8 } },
  { name: "Bangkok Street Eats", address: "37480 Fremont Blvd", city: "Fremont", zip: "94536", phone: "(510) 555-0103", lat: 37.5575, lng: -121.9998,
    dishes: { "Pad Thai" => 4.8, "Tom Yum Soup" => 4.7, "Pad See Ew" => 4.5, "Basil Fried Rice with Pork" => 4.8, "Papaya Salad" => 4.4 } },
  { name: "Siam Garden", address: "40900 Fremont Blvd", city: "Fremont", zip: "94538", phone: "(510) 555-0104", lat: 37.5262, lng: -121.9679,
    dishes: { "Pad Thai" => 4.2, "Tom Yum Soup" => 4.5, "Tom Kha Gai" => 4.4, "Papaya Salad" => 4.0, "Green Curry" => 4.1 } },
  { name: "Lemongrass & Lime", address: "43430 Mission Blvd", city: "Fremont", zip: "94539", phone: "(510) 555-0105", lat: 37.5305, lng: -121.9195,
    dishes: { "Pad Thai" => 4.5, "Green Curry" => 4.6, "Mango Sticky Rice" => 4.8, "Pad See Ew" => 4.2 } },
  { name: "Chiang Mai Noodle House", address: "46850 Warm Springs Blvd", city: "Fremont", zip: "94539", phone: "(510) 555-0106", lat: 37.4885, lng: -121.9290,
    dishes: { "Khao Soi" => 4.9, "Pad Thai" => 4.3, "Tom Yum Soup" => 4.6, "Thai Fried Rice" => 4.1 } },
  { name: "Royal Thai Bistro", address: "39410 Cedar Blvd", city: "Newark", zip: "94560", phone: "(510) 555-0107", lat: 37.5265, lng: -122.0005,
    dishes: { "Pad Thai" => 3.8, "Tom Yum Soup" => 4.0, "Pad See Ew" => 4.1, "Tom Kha Gai" => 3.9 } },
  { name: "Krua Thai Cafe", address: "1780 Decoto Rd", city: "Union City", zip: "94587", phone: "(510) 555-0108", lat: 37.5901, lng: -122.0290,
    dishes: { "Pad Thai" => 4.4, "Tom Yum Soup" => 4.1, "Basil Fried Rice with Pork" => 4.6 } },
  { name: "Pattaya Kitchen", address: "4949 Stevenson Blvd", city: "Fremont", zip: "94538", phone: "(510) 555-0109", lat: 37.5315, lng: -121.9582,
    dishes: { "Pad Thai" => nil, "Tom Yum Soup" => nil, "Green Curry" => nil } },
  { name: "Golden Elephant Thai", address: "600 E Calaveras Blvd", city: "Milpitas", zip: "95035", phone: "(408) 555-0110", lat: 37.4330, lng: -121.8930,
    dishes: { "Pad Thai" => 4.7, "Tom Yum Soup" => 4.5, "Tom Kha Gai" => 4.6 } },
  { name: "Bay Thai Cuisine", address: "22540 Foothill Blvd", city: "Hayward", zip: "94541", phone: "(510) 555-0111", lat: 37.6745, lng: -122.0835,
    dishes: { "Pad Thai" => 4.0, "Tom Yum Soup" => 4.2 } },
  { name: "Mission Street Thai", address: "2600 Mission St", city: "San Francisco", zip: "94110", phone: "(415) 555-0112", lat: 37.7550, lng: -122.4190,
    dishes: { "Pad Thai" => 4.6, "Tom Yum Soup" => 4.3, "Khao Soi" => 4.4 } },

  # American classics.
  { name: "Mission Peak Burgers", address: "43360 Mission Blvd", city: "Fremont", zip: "94539", phone: "(510) 555-0113", lat: 37.5297, lng: -121.9205,
    dishes: { "Hamburger" => 4.5, "Cheeseburger" => 4.7, "Hot Dog" => 3.9, "Fried Chicken" => 3.8 } },
  { name: "Smokestack BBQ Co.", address: "43950 Pacific Commons Blvd", city: "Fremont", zip: "94538", phone: "(510) 555-0114", lat: 37.4990, lng: -121.9745,
    dishes: { "Barbecue Ribs" => 4.6, "Brisket" => 4.8, "Fried Chicken" => 4.2, "Hot Dog" => 3.6 } },
  { name: "Niles Canyon Diner", address: "37690 Niles Blvd", city: "Fremont", zip: "94536", phone: "(510) 555-0115", lat: 37.5770, lng: -121.9800,
    dishes: { "Meatloaf" => 4.6, "Hamburger" => 4.1, "Cheeseburger" => 4.2, "Fried Chicken" => 4.4, "Hot Dog" => 4.0 } },
  { name: "Centerville Pizza Co.", address: "37400 Fremont Blvd", city: "Fremont", zip: "94536", phone: "(510) 555-0116", lat: 37.5585, lng: -122.0003,
    dishes: { "Pizza" => 4.3, "Chicken Parmesan" => 3.9 } },
  { name: "Ardenwood Grill", address: "5100 Paseo Padre Pkwy", city: "Fremont", zip: "94555", phone: "(510) 555-0117", lat: 37.5553, lng: -122.0476,
    dishes: { "Hamburger" => 4.0, "Cheeseburger" => 4.3, "Barbecue Ribs" => 3.9, "Meatloaf" => 3.7 } },
  { name: "Big Tony's Pizzeria", address: "35980 Newark Blvd", city: "Newark", zip: "94560", phone: "(510) 555-0118", lat: 37.5330, lng: -122.0350,
    dishes: { "Pizza" => 4.6, "Chicken Parmesan" => 4.2, "Lasagna" => 4.0 } },
  { name: "Union City Smokehouse", address: "33500 Alvarado Niles Rd", city: "Union City", zip: "94587", phone: "(510) 555-0119", lat: 37.5935, lng: -122.0560,
    dishes: { "Brisket" => 4.3, "Barbecue Ribs" => 4.4, "Fried Chicken" => 4.0, "Meatloaf" => 3.8 } },

  # Everything else.
  { name: "Pho Saigon Noodle", address: "4288 Mowry Ave", city: "Fremont", zip: "94538", phone: "(510) 555-0120", lat: 37.5450, lng: -121.9740,
    dishes: { "Pho" => 4.5, "Banh Mi" => 4.2, "Bun Bo Hue" => 4.6, "Spring Rolls" => 4.1 } },
  { name: "Tandoori Nights", address: "40645 Fremont Blvd", city: "Fremont", zip: "94538", phone: "(510) 555-0121", lat: 37.5292, lng: -121.9700,
    dishes: { "Butter Chicken" => 4.6, "Chicken Tikka Masala" => 4.4, "Chicken Biryani" => 4.3, "Palak Paneer" => 4.2 } },
  { name: "Dosa Corner", address: "3100 Walnut Ave", city: "Fremont", zip: "94538", phone: "(510) 555-0122", lat: 37.5480, lng: -121.9790,
    dishes: { "Masala Dosa" => 4.7, "Chicken Biryani" => 4.5, "Palak Paneer" => 4.0 } },
  { name: "Kabul Kitchen", address: "37395 Fremont Blvd", city: "Fremont", zip: "94536", phone: "(510) 555-0123", lat: 37.5595, lng: -121.9995,
    dishes: { "Kabuli Pulao" => 4.7, "Mantu" => 4.8, "Chapli Kebab" => 4.4, "Bolani" => 4.5 } },
  { name: "Taqueria El Sol", address: "4051 Irvington Ave", city: "Fremont", zip: "94538", phone: "(510) 555-0124", lat: 37.5230, lng: -121.9640,
    dishes: { "Tacos al Pastor" => 4.6, "Carne Asada Burrito" => 4.5, "Enchiladas" => 4.1, "Pozole" => 4.3 } },
  { name: "Dragon Well Kitchen", address: "46801 Warm Springs Blvd", city: "Fremont", zip: "94539", phone: "(510) 555-0125", lat: 37.4895, lng: -121.9300,
    dishes: { "Kung Pao Chicken" => 4.2, "Mapo Tofu" => 4.5, "Xiao Long Bao" => 4.6, "Chow Mein" => 3.9 } },
  { name: "Golden Lotus Dim Sum", address: "1535 Landess Ave", city: "Milpitas", zip: "95035", phone: "(408) 555-0126", lat: 37.4190, lng: -121.8750,
    dishes: { "Xiao Long Bao" => 4.4, "Peking Duck" => 4.7, "Chow Mein" => 4.0 } },
  { name: "Sakura Ramen House", address: "35201 Newark Blvd", city: "Newark", zip: "94560", phone: "(510) 555-0127", lat: 37.5360, lng: -122.0330,
    dishes: { "Tonkotsu Ramen" => 4.6, "Tonkatsu" => 4.3, "Shrimp Tempura" => 4.2 } },
  { name: "Umi Sushi Bar", address: "5180 Mowry Ave", city: "Fremont", zip: "94538", phone: "(510) 555-0128", lat: 37.5395, lng: -121.9955,
    dishes: { "Sushi" => 4.5, "Shrimp Tempura" => 4.3, "Tonkotsu Ramen" => 3.9 } },
  { name: "Seoul Kitchen BBQ", address: "34420 Fremont Blvd", city: "Fremont", zip: "94555", phone: "(510) 555-0129", lat: 37.5760, lng: -122.0420,
    dishes: { "Bibimbap" => 4.4, "Korean Fried Chicken" => 4.7, "Bulgogi" => 4.5, "Kimchi Jjigae" => 4.3 } },
  { name: "Trattoria Bella", address: "39237 Paseo Padre Pkwy", city: "Fremont", zip: "94538", phone: "(510) 555-0130", lat: 37.5485, lng: -121.9820,
    dishes: { "Spaghetti Carbonara" => 4.5, "Lasagna" => 4.6, "Margherita Pizza" => 4.3, "Mushroom Risotto" => 4.2, "Chicken Parmesan" => 4.4 } },
  { name: "Nonna's Table", address: "150 S 1st St", city: "San Jose", zip: "95113", phone: "(408) 555-0131", lat: 37.3339, lng: -121.8896,
    dishes: { "Spaghetti Carbonara" => 4.8, "Lasagna" => 4.7, "Margherita Pizza" => 4.5 } }
].freeze

REVIEWERS = [
  "Maya Patel", "Jordan Lee", "Priya Shah", "Carlos Mendoza", "Ken Tanaka", "Aisha Rahman",
  "Tom Walker", "Linh Nguyen", "Sofia Rossi", "Omar Haidari", "Grace Kim", "Ben Carter"
].freeze

REVIEW_TEXT = {
  5 => [
    "Hands down the best %{dish} I've had around here. Perfectly balanced and a generous portion.",
    "Outstanding %{dish}! Fresh ingredients, and you can tell it's made with care. I'll be back.",
    "The %{dish} here is the real deal. My go-to spot whenever the craving hits.",
    "Wow. The %{dish} was incredible: great flavor, great texture, great value."
  ],
  4 => [
    "Really good %{dish}. Not quite perfect, but I'd happily order it again.",
    "Solid %{dish} with lots of flavor. The portion was a little small for the price.",
    "Tasty %{dish} that came out hot and fast. A reliable choice.",
    "Very good %{dish}, a touch too salty for me but otherwise excellent."
  ],
  3 => [
    "The %{dish} was okay. Decent, but nothing memorable.",
    "Average %{dish}. Some visits are better than others.",
    "Fine %{dish}, but I've had better nearby."
  ],
  2 => [
    "Disappointing %{dish}: bland and a bit greasy.",
    "The %{dish} was lukewarm and underseasoned. Expected more."
  ],
  1 => [
    "Couldn't finish the %{dish}. Would not order it again.",
    "Worst %{dish} I've had in a while. Hopefully it was an off night."
  ]
}.freeze

# Integer ratings whose mean is as close as possible to `target`, with some spread.
def demo_ratings(target, count, rng)
  total = (target * count).round
  base, extra = total.divmod(count)
  ratings = Array.new(count) { |i| i < extra ? base + 1 : base }
  (count / 2).times do
    i = rng.rand(count)
    j = rng.rand(count)
    next if i == j || ratings[i] >= 5 || ratings[j] <= 1 || rng.rand > 0.4

    ratings[i] += 1
    ratings[j] -= 1
  end
  ratings.shuffle(random: rng)
end

rng = Random.new(2026)

ActiveRecord::Base.transaction do
  dishes = {}
  CATALOG.each do |(cuisine_name, emoji), cuisine_dishes|
    cuisine = Cuisine.find_or_create_by!(name: cuisine_name) { |c| c.emoji = emoji }
    cuisine_dishes.each do |dish_name, (aliases, description)|
      dishes[dish_name] = cuisine.dishes.find_or_create_by!(name: dish_name) do |dish|
        dish.aliases = aliases.presence
        dish.description = description
      end
    end
  end

  User.find_or_create_by!(email: "demo@example.com") do |user|
    user.name = "Demo Diner"
    user.password = DEMO_PASSWORD
  end
  reviewers = REVIEWERS.map do |name|
    User.find_or_create_by!(email: "#{name.downcase.tr(' ', '.')}@example.com") do |user|
      user.name = name
      user.password = DEMO_PASSWORD
    end
  end

  RESTAURANTS.each do |attrs|
    restaurant = Restaurant.find_or_create_by!(name: attrs[:name], city: attrs[:city]) do |r|
      r.assign_attributes(address: attrs[:address], state: "CA", zip_code: attrs[:zip], phone: attrs[:phone],
                          latitude: attrs[:lat], longitude: attrs[:lng])
    end

    attrs[:dishes].each do |dish_name, target_rating|
      restaurant_dish = restaurant.serve!(dishes.fetch(dish_name))
      next if target_rating.nil?

      count = rng.rand(4..REVIEWERS.size)
      ratings = demo_ratings(target_rating, count, rng)
      reviewers.sample(count, random: rng).zip(ratings).each do |user, rating|
        review = restaurant_dish.reviews.find_or_initialize_by(user: user)
        body = rng.rand < 0.15 ? nil : format(REVIEW_TEXT.fetch(rating).sample(random: rng), dish: dish_name)
        posted_at = rng.rand(1..400).days.ago - rng.rand(0..86_399).seconds
        review.update!(rating: rating, body: body, created_at: posted_at, updated_at: posted_at)
      end
    end
  end
end

puts "Seeded #{Cuisine.count} cuisines, #{Dish.count} dishes, #{Restaurant.count} restaurants, " \
     "#{RestaurantDish.count} menu items, #{Review.count} reviews and #{User.count} users."
puts "Sign in with demo@example.com / #{DEMO_PASSWORD}"
