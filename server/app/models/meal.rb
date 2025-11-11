# == Schema Information
#
# Table name: meals
#
#  id         :uuid             not null, primary key
#  user_id    :uuid             not null
#  date       :date             not null
#  meal_type  :string(20)       not null
#  name       :string(255)
#  notes      :text
#  image_url  :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Meal < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :meal_entries, dependent: :destroy
  has_many :foods, through: :meal_entries

  # Validations
  validates :date, presence: true
  validates :meal_type, presence: true, inclusion: {
    in: %w[breakfast lunch dinner snack]
  }
  validates :name, length: { maximum: 255 }, allow_nil: true

  # Scopes
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :by_type, ->(type) { where(meal_type: type) }
  scope :recent, -> { order(date: :desc, created_at: :desc) }

  # Accepts nested attributes for meal entries
  accepts_nested_attributes_for :meal_entries, allow_destroy: true

  # Instance methods
  def total_nutrition
    return {} if meal_entries.empty?

    totals = {
      'calories' => 0,
      'proteinG' => 0,
      'carbsG' => 0,
      'fatG' => 0,
      'fiberG' => 0,
      'sugarG' => 0,
      'saturatedFatG' => 0,
      'transFatG' => 0,
      'cholesterolMg' => 0,
      'sodiumMg' => 0,
      'potassiumMg' => 0,
      'vitaminAMcg' => 0,
      'vitaminCMg' => 0,
      'calciumMg' => 0,
      'ironMg' => 0
    }

    meal_entries.includes(:food).each do |entry|
      entry_nutrition = entry.calculated_nutrition

      totals.keys.each do |nutrient|
        totals[nutrient] += (entry_nutrition[nutrient] || 0)
      end
    end

    totals.transform_values { |v| v.round(2) }
  end

  def total_calories
    total_nutrition['calories'] || 0
  end
end
