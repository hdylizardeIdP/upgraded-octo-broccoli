# app/serializers/meal_serializer.rb
# Using ActiveModel::Serializer for JSON API responses

class MealSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :date, :meal_type, :name, :notes, :image_url,
             :total_nutrition, :created_at, :updated_at

  has_many :meal_entries

  def total_nutrition
    object.total_nutrition
  end

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end

# app/serializers/meal_entry_serializer.rb
class MealEntrySerializer < ActiveModel::Serializer
  attributes :id, :food_id, :servings, :nutrition

  belongs_to :food

  def nutrition
    object.calculated_nutrition
  end
end

# app/serializers/food_serializer.rb
class FoodSerializer < ActiveModel::Serializer
  attributes :id, :fdc_id, :name, :brand, :serving_size, :serving_unit,
             :nutrition, :barcode, :image_url, :is_custom, :created_at, :updated_at

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end

# app/serializers/user_serializer.rb
class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :date_of_birth, :gender, :height_cm,
             :weight_kg, :activity_level, :goals, :created_at, :updated_at

  def created_at
    object.created_at.iso8601
  end

  def updated_at
    object.updated_at.iso8601
  end
end
