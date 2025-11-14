class WaterIntakeSerializer < ActiveModel::Serializer
  attributes :id, :user_id, :date, :amount_ml, :created_at, :updated_at

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      userId: hash[:user_id],
      date: hash[:date],
      amountMl: hash[:amount_ml],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
