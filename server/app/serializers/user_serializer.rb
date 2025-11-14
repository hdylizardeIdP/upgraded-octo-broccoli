class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :name, :date_of_birth, :gender, :height_cm, :weight_kg,
             :activity_level, :goals, :created_at, :updated_at

  # Transform attribute names to camelCase for frontend
  def date_of_birth
    object.date_of_birth
  end

  def height_cm
    object.height_cm
  end

  def weight_kg
    object.weight_kg
  end

  def activity_level
    object.activity_level
  end

  def created_at
    object.created_at
  end

  def updated_at
    object.updated_at
  end

  # Computed attributes
  attribute :age
  attribute :bmr
  attribute :tdee

  def age
    object.age
  end

  def bmr
    object.calculate_bmr
  end

  def tdee
    object.calculate_tdee
  end

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      email: hash[:email],
      name: hash[:name],
      dateOfBirth: hash[:date_of_birth],
      gender: hash[:gender],
      heightCm: hash[:height_cm],
      weightKg: hash[:weight_kg],
      activityLevel: hash[:activity_level],
      goals: hash[:goals],
      age: hash[:age],
      bmr: hash[:bmr],
      tdee: hash[:tdee],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
