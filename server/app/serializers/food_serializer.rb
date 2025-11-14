class FoodSerializer < ActiveModel::Serializer
  attributes :id, :name, :brand, :serving_size, :serving_unit, :nutrition,
             :barcode, :usda_id, :is_custom, :user_id, :created_at, :updated_at

  # Return attributes in camelCase format
  def attributes(*args)
    hash = super
    {
      id: hash[:id],
      name: hash[:name],
      brand: hash[:brand],
      servingSize: hash[:serving_size],
      servingUnit: hash[:serving_unit],
      nutrition: hash[:nutrition],
      barcode: hash[:barcode],
      usdaId: hash[:usda_id],
      isCustom: hash[:is_custom],
      userId: hash[:user_id],
      createdAt: hash[:created_at],
      updatedAt: hash[:updated_at]
    }
  end
end
