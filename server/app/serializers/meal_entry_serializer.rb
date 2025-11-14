class MealEntrySerializer < ActiveModel::Serializer
  attributes :id, :meal_id, :food_id, :servings, :created_at, :updated_at

  # Include the food details and calculated nutrition
  belongs_to :food

  attribute :calculated_nutrition
  attribute :calories

  def calculated_nutrition
    object.calculated_nutrition
  end

  def calories
    object.calories
  end

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      mealId: hash[:meal_id],
      foodId: hash[:food_id],
      servings: hash[:servings],
      calculatedNutrition: hash[:calculated_nutrition],
      calories: hash[:calories],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
