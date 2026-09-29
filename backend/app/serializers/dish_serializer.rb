class DishSerializer
  def self.render(dish)
    {
      id: dish.id,
      name: dish.name,
      aliases: dish.alias_list,
      description: dish.description,
      cuisine: CuisineSerializer.summary(dish.cuisine),
      restaurants_count: dish.restaurant_dishes_count
    }
  end
end
