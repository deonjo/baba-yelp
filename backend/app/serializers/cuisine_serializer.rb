class CuisineSerializer
  def self.render(cuisine)
    { id: cuisine.id, name: cuisine.name, emoji: cuisine.emoji, dishes_count: cuisine.dishes_count }
  end

  def self.summary(cuisine)
    { id: cuisine.id, name: cuisine.name, emoji: cuisine.emoji }
  end
end
