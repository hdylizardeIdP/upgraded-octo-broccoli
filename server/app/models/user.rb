# == Schema Information
#
# Table name: users
#
#  id              :uuid             not null, primary key
#  email           :string           not null
#  password_digest :string           not null
#  name            :string           not null
#  date_of_birth   :date
#  gender          :string
#  height_cm       :integer
#  weight_kg       :decimal(5, 2)
#  activity_level  :string
#  goals           :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :meals, dependent: :destroy
  has_many :foods, -> { where(is_custom: true) }, foreign_key: :user_id, dependent: :destroy
  has_many :water_intakes, dependent: :destroy
  has_many :weights, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true, length: { minimum: 2, maximum: 255 }
  validates :password, length: { minimum: 8 }, if: -> { new_record? || !password.nil? }
  validates :gender, inclusion: { in: %w[male female other], allow_nil: true }
  validates :activity_level, inclusion: {
    in: %w[sedentary light moderate active very_active],
    allow_nil: true
  }
  validates :height_cm, numericality: { greater_than: 0, less_than_or_equal_to: 300 },
            allow_nil: true
  validates :weight_kg, numericality: { greater_than: 0, less_than_or_equal_to: 500 },
            allow_nil: true

  # Callbacks
  before_save :downcase_email

  # Instance methods
  def age
    return nil unless date_of_birth
    ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
  end

  # Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation
  def calculate_bmr
    return nil unless weight_kg && height_cm && age && gender

    if gender == 'male'
      (10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5
    elsif gender == 'female'
      (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161
    else
      # Use average for 'other' or unknown gender
      (10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 78
    end
  end

  # Calculate Total Daily Energy Expenditure (TDEE)
  def calculate_tdee
    return nil unless calculate_bmr && activity_level

    multipliers = {
      'sedentary' => 1.2,
      'light' => 1.375,
      'moderate' => 1.55,
      'active' => 1.725,
      'very_active' => 1.9
    }

    calculate_bmr * multipliers[activity_level]
  end

  private

  def downcase_email
    self.email = email.downcase if email.present?
  end
end
