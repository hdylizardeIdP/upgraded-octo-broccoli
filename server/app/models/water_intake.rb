# == Schema Information
#
# Table name: water_intakes
#
#  id         :uuid             not null, primary key
#  user_id    :uuid             not null
#  date       :date             not null
#  amount_ml  :integer          not null
#  time       :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class WaterIntake < ApplicationRecord
  # Associations
  belongs_to :user

  # Validations
  validates :date, presence: true
  validates :amount_ml, presence: true, numericality: {
    greater_than: 0,
    less_than_or_equal_to: 10000 # 10 liters max per entry
  }
  validates :time, presence: true

  # Scopes
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }
  scope :recent, -> { order(date: :desc, time: :desc) }

  # Class methods
  def self.total_for_date(user, date)
    for_user(user).for_date(date).sum(:amount_ml)
  end

  def self.daily_totals(user, start_date, end_date)
    for_user(user)
      .for_date_range(start_date, end_date)
      .group(:date)
      .sum(:amount_ml)
  end

  # Instance methods
  def amount_in_liters
    (amount_ml / 1000.0).round(2)
  end

  def amount_in_oz
    (amount_ml * 0.033814).round(2)
  end
end
