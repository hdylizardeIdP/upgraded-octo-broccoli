# == Schema Information
#
# Table name: weights
#
#  id         :uuid             not null, primary key
#  user_id    :uuid             not null
#  date       :date             not null
#  weight_kg  :decimal(5, 2)    not null
#  notes      :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Weight < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :date, presence: true, uniqueness: { scope: :user_id }
  validates :weight_kg, presence: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 500
  }

  # Scopes
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, -> { order(date: :desc) }
  scope :chronological, -> { order(date: :asc) }

  # Class methods
  def self.latest_for_user(user)
    for_user(user).recent.first
  end

  def self.weight_change(user, start_date, end_date)
    weights = for_user(user).for_date_range(start_date, end_date).chronological
    return nil if weights.count < 2

    first_weight = weights.first.weight_kg
    last_weight = weights.last.weight_kg

    {
      change_kg: (last_weight - first_weight).round(2),
      change_percent: (((last_weight - first_weight) / first_weight) * 100).round(2),
      start_weight: first_weight,
      end_weight: last_weight
    }
  end

  # Instance methods
  def weight_in_lbs
    (weight_kg * 2.20462).round(2)
  end

  def bmi(height_cm)
    return nil unless height_cm

    height_m = height_cm / 100.0
    (weight_kg / (height_m ** 2)).round(2)
  end
end
