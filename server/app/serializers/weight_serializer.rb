class WeightSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :date, :weight_kg, :notes, :created_at, :updated_at

  # Computed attributes
  attribute :bmi
  attribute :weight_change

  def bmi
    object.bmi
  end

  def weight_change
    object.weight_change
  end

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      userId: hash[:user_id],
      date: hash[:date],
      weightKg: hash[:weight_kg],
      notes: hash[:notes],
      bmi: hash[:bmi],
      weightChange: hash[:weight_change],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
