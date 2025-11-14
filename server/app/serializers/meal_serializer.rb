class MealSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :date, :meal_type, :name, :notes, :image_url,
             :created_at, :updated_at

  # Include meal entries with their foods
  has_many :meal_entries

  # Computed attributes
  attribute :total_nutrition
  attribute :total_calories

  def total_nutrition
    object.total_nutrition
  end

  def total_calories
    object.total_calories
  end

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      userId: hash[:user_id],
      date: hash[:date],
      mealType: hash[:meal_type],
      name: hash[:name],
      notes: hash[:notes],
      imageUrl: hash[:image_url],
      totalNutrition: hash[:total_nutrition],
      totalCalories: hash[:total_calories],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
