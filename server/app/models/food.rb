# == Schema Information
#
# Table name: foods
#
#  id           :uuid             not null, primary key
#  fdc_id       :integer
#  name         :string(500)      not null
#  brand        :string(255)
#  serving_size :decimal(10, 2)   not null
#  serving_unit :string(50)       not null
#  nutrition    :jsonb            not null
#  barcode      :string(50)
#  image_url    :text
#  is_custom    :boolean          default(FALSE)
#  user_id      :uuid
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Food < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  has_many :meal_entries, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, length: { maximum: 500 }
  validates :serving_size, presence: true, numericality: { greater_than: 0 }
  validates :serving_unit, presence: true, inclusion: {
    in: %w[g ml oz cup tbsp tsp piece slice serving]
  }
  validates :nutrition, presence: true
  validates :fdc_id, uniqueness: true, allow_nil: true
  validates :barcode, uniqueness: true, allow_nil: true
  validate :validate_nutrition_structure
  validate :custom_food_requires_user

  # Scopes
  scope :usda, -> { where(is_custom: false) }
  scope :custom_for_user, ->(user) { where(is_custom: true, user_id: user.id) }
  scope :search_by_name, ->(query) {
    where('name ILIKE ?', "%#{sanitize_sql_like(query)}%")
  }

  # Class methods
  def self.search(query, user = nil, include_custom: true)
    results = usda.search_by_name(query)

    if include_custom && user
      custom_results = custom_for_user(user).search_by_name(query)
      results = results.or(custom_results)
    end

    results.order(:name).limit(20)
  end

  # Instance methods
  def custom?
    is_custom
  end

  def usda?
    !is_custom
  end

  private

  def validate_nutrition_structure
    return if nutrition.blank?

    required_keys = %w[calories proteinG carbsG fatG]
    missing_keys = required_keys - nutrition.keys

    if missing_keys.any?
      errors.add(:nutrition, "must include: #{missing_keys.join(', ')}")
    end

    # Validate numeric values
    nutrition.each do |key, value|
      unless value.is_a?(Numeric) || value.nil?
        errors.add(:nutrition, "#{key} must be a number")
      end
    end
  end

  def custom_food_requires_user
    if is_custom && user_id.nil?
      errors.add(:user_id, "is required for custom foods")
    end
  end
end
