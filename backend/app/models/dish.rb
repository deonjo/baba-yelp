class Dish < ApplicationRecord
  belongs_to :cuisine, counter_cache: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :restaurant_dishes, dependent: :restrict_with_error
  has_many :restaurants, through: :restaurant_dishes

  normalizes :name, with: ->(name) { name.squish }
  normalizes :aliases, with: ->(aliases) { aliases.split(",").map(&:squish).compact_blank.join(", ").presence }

  validates :name, presence: true, length: { maximum: 80 },
                   uniqueness: { scope: :cuisine_id, case_sensitive: false }
  validates :aliases, length: { maximum: 255 }
  validates :description, length: { maximum: 1000 }

  # Matches dish names, aliases and cuisine names. Name matches come first
  # (prefix matches before substring matches), then popular dishes.
  scope :search, ->(query) {
    term = query.to_s.squish
    next all if term.blank?

    contains = "%#{sanitize_sql_like(term)}%"
    prefix = "#{sanitize_sql_like(term)}%"
    joins(:cuisine)
      .where("dishes.name LIKE :contains OR dishes.aliases LIKE :contains OR cuisines.name LIKE :contains", contains: contains)
      .reorder(Arel.sql(sanitize_sql_array([ <<~SQL.squish, prefix, contains, contains ])))
        CASE WHEN dishes.name LIKE ? THEN 0
             WHEN dishes.name LIKE ? THEN 1
             WHEN dishes.aliases LIKE ? THEN 2
             ELSE 3 END,
        dishes.restaurant_dishes_count DESC,
        dishes.name
      SQL
  }

  scope :ordered, -> { order(restaurant_dishes_count: :desc, name: :asc) }

  def alias_list
    aliases.to_s.split(",").map(&:strip).compact_blank
  end
end
