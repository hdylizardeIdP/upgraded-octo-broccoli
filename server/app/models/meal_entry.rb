# == Schema Information
#
# Table name: meal_entries
#
#  id         :uuid             not null, primary key
#  meal_id    :uuid             not null
#  food_id    :uuid             not null
#  servings   :decimal(10, 2)   default(1.0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class MealEntry < ApplicationRecord
  # Associations
  belongs_to :meal
  belongs_to :food

  # Validations
  validates :servings, presence: true, numericality: { greater_than: 0 }

  # Instance methods
  # Calculate nutrition for this entry (food nutrition × servings)
  def calculated_nutrition
    return {} unless food&.nutrition

    food.nutrition.transform_values do |value|
      next 0 if value.nil?
      (value.to_f * servings.to_f).round(2)
    end
  end

  def calories
    calculated_nutrition['calories'] || 0
  end
end
