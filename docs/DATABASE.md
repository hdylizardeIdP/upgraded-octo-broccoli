# Database Schema

## Overview

PostgreSQL database optimized for nutrition tracking with strong referential integrity and indexing for performance.

## Entity Relationship Diagram

```
Users
  ├─→ Meals (one-to-many)
  │    └─→ MealEntries (one-to-many)
  │         └─→ Foods (many-to-one)
  ├─→ CustomFoods (one-to-many)
  ├─→ WaterIntakes (one-to-many)
  └─→ Weights (one-to-many)
```

---

## Tables

### users

Primary user account table.

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  date_of_birth DATE,
  gender VARCHAR(20),
  height_cm INTEGER,
  weight_kg DECIMAL(5,2),
  activity_level VARCHAR(20),
  goals JSONB DEFAULT '{}',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

**Fields:**
- `id`: UUID primary key
- `email`: Unique user email (indexed)
- `password_digest`: bcrypt hashed password
- `name`: User's display name
- `date_of_birth`: Optional birthdate for BMR calculations
- `gender`: male, female, or other
- `height_cm`: Height in centimeters
- `weight_kg`: Current weight in kilograms
- `activity_level`: sedentary, light, moderate, active, very_active
- `goals`: JSON object storing nutrition goals
  ```json
  {
    "dailyCalories": 2200,
    "proteinGrams": 165,
    "carbsGrams": 220,
    "fatGrams": 73,
    "fiberGrams": 25,
    "sodiumMg": 2300
  }
  ```

---

### foods

Master food database (USDA + custom foods).

```sql
CREATE TABLE foods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fdc_id INTEGER UNIQUE,  -- USDA FoodData Central ID
  name VARCHAR(500) NOT NULL,
  brand VARCHAR(255),
  serving_size DECIMAL(10,2) NOT NULL,
  serving_unit VARCHAR(50) NOT NULL,
  nutrition JSONB NOT NULL,
  barcode VARCHAR(50),
  image_url TEXT,
  is_custom BOOLEAN DEFAULT FALSE,
  user_id UUID,  -- NULL for USDA foods, set for custom foods
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_foods_name ON foods USING gin(to_tsvector('english', name));
CREATE INDEX idx_foods_fdc_id ON foods(fdc_id);
CREATE INDEX idx_foods_barcode ON foods(barcode);
CREATE INDEX idx_foods_user_id ON foods(user_id);
CREATE INDEX idx_foods_is_custom ON foods(is_custom);
```

**Fields:**
- `id`: UUID primary key
- `fdc_id`: USDA database ID (null for custom foods)
- `name`: Food name (full-text indexed)
- `brand`: Brand name if applicable
- `serving_size`: Size of one serving
- `serving_unit`: Unit (g, ml, cup, etc.)
- `nutrition`: JSON object with all nutrition data
  ```json
  {
    "calories": 95,
    "proteinG": 0.5,
    "carbsG": 25,
    "fatG": 0.3,
    "fiberG": 4.4,
    "sugarG": 19,
    "saturatedFatG": 0.1,
    "transFatG": 0,
    "cholesterolMg": 0,
    "sodiumMg": 2,
    "potassiumMg": 195,
    "vitaminAMcg": 5,
    "vitaminCMg": 8.4,
    "calciumMg": 11,
    "ironMg": 0.2
  }
  ```
- `barcode`: Product barcode (UPC/EAN)
- `image_url`: Food image URL
- `is_custom`: True if user-created food
- `user_id`: Owner for custom foods

---

### meals

User's logged meals.

```sql
CREATE TABLE meals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  meal_type VARCHAR(20) NOT NULL,
  name VARCHAR(255),
  notes TEXT,
  image_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  CONSTRAINT meal_type_check CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack'))
);

CREATE INDEX idx_meals_user_date ON meals(user_id, date DESC);
CREATE INDEX idx_meals_user_id ON meals(user_id);
CREATE INDEX idx_meals_date ON meals(date);
```

**Fields:**
- `id`: UUID primary key
- `user_id`: Owner of meal
- `date`: Date meal was consumed
- `meal_type`: breakfast, lunch, dinner, or snack
- `name`: Optional meal name
- `notes`: User notes
- `image_url`: Photo of meal
- Composite index on (user_id, date) for efficient queries

---

### meal_entries

Individual food items in a meal.

```sql
CREATE TABLE meal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_id UUID NOT NULL,
  food_id UUID NOT NULL,
  servings DECIMAL(10,2) NOT NULL DEFAULT 1.0,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (meal_id) REFERENCES meals(id) ON DELETE CASCADE,
  FOREIGN KEY (food_id) REFERENCES foods(id) ON DELETE RESTRICT,
  
  CONSTRAINT servings_positive CHECK (servings > 0)
);

CREATE INDEX idx_meal_entries_meal_id ON meal_entries(meal_id);
CREATE INDEX idx_meal_entries_food_id ON meal_entries(food_id);
```

**Fields:**
- `id`: UUID primary key
- `meal_id`: Parent meal
- `food_id`: Food item reference
- `servings`: Number of servings (can be decimal, e.g., 1.5)
- ON DELETE CASCADE: Entries deleted when meal deleted
- ON DELETE RESTRICT: Cannot delete food if used in meal

---

### water_intakes

Daily water consumption tracking.

```sql
CREATE TABLE water_intakes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  amount_ml INTEGER NOT NULL,
  time TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  CONSTRAINT amount_positive CHECK (amount_ml > 0)
);

CREATE INDEX idx_water_intakes_user_date ON water_intakes(user_id, date DESC);
```

---

### weights

Body weight tracking over time.

```sql
CREATE TABLE weights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  date DATE NOT NULL,
  weight_kg DECIMAL(5,2) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  
  CONSTRAINT weight_positive CHECK (weight_kg > 0),
  UNIQUE(user_id, date)
);

CREATE INDEX idx_weights_user_date ON weights(user_id, date DESC);
```

**Note:** One weight entry per user per day (enforced by unique constraint).

---

## Rails Migrations

### Initial Setup

```bash
rails g model User email:string password_digest:string name:string \
  date_of_birth:date gender:string height_cm:integer weight_kg:decimal \
  activity_level:string goals:jsonb

rails g model Food fdc_id:integer name:string brand:string \
  serving_size:decimal serving_unit:string nutrition:jsonb \
  barcode:string image_url:text is_custom:boolean user:references

rails g model Meal user:references date:date meal_type:string \
  name:string notes:text image_url:text

rails g model MealEntry meal:references food:references servings:decimal

rails g model WaterIntake user:references date:date amount_ml:integer time:datetime

rails g model Weight user:references date:date weight_kg:decimal notes:text
```

### Custom Migration Tweaks

After generating, modify migrations:

**Migration: CreateUsers**
```ruby
class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.date :date_of_birth
      t.string :gender
      t.integer :height_cm
      t.decimal :weight_kg, precision: 5, scale: 2
      t.string :activity_level
      t.jsonb :goals, default: {}

      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

**Migration: CreateFoods**
```ruby
class CreateFoods < ActiveRecord::Migration[7.1]
  def change
    create_table :foods, id: :uuid do |t|
      t.integer :fdc_id
      t.string :name, null: false
      t.string :brand
      t.decimal :serving_size, precision: 10, scale: 2, null: false
      t.string :serving_unit, null: false
      t.jsonb :nutrition, null: false
      t.string :barcode
      t.text :image_url
      t.boolean :is_custom, default: false
      t.references :user, type: :uuid, foreign_key: { on_delete: :cascade }

      t.timestamps
    end

    add_index :foods, :fdc_id, unique: true
    add_index :foods, :barcode
    add_index :foods, :is_custom
    
    # Full-text search on name
    execute <<-SQL
      CREATE INDEX idx_foods_name ON foods USING gin(to_tsvector('english', name));
    SQL
  end
end
```

---

## Rails Models

### User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  has_many :meals, dependent: :destroy
  has_many :custom_foods, class_name: 'Food', dependent: :destroy
  has_many :water_intakes, dependent: :destroy
  has_many :weights, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validates :gender, inclusion: { in: %w[male female other] }, allow_nil: true
  validates :activity_level, inclusion: { in: %w[sedentary light moderate active very_active] }, allow_nil: true

  def age
    return nil unless date_of_birth
    ((Date.today - date_of_birth) / 365.25).floor
  end
end
```

### Food Model

```ruby
# app/models/food.rb
class Food < ApplicationRecord
  belongs_to :user, optional: true
  has_many :meal_entries, dependent: :restrict_with_error

  validates :name, presence: true
  validates :serving_size, presence: true, numericality: { greater_than: 0 }
  validates :serving_unit, presence: true
  validates :nutrition, presence: true

  scope :usda, -> { where(is_custom: false) }
  scope :custom_for_user, ->(user) { where(is_custom: true, user: user) }

  def self.search(query, user: nil, include_custom: true)
    foods = where("to_tsvector('english', name) @@ plainto_tsquery('english', ?)", query)
    
    if include_custom && user
      foods = foods.or(custom_for_user(user).where("name ILIKE ?", "%#{query}%"))
    elsif !include_custom
      foods = foods.usda
    end
    
    foods
  end
end
```

### Meal Model

```ruby
# app/models/meal.rb
class Meal < ApplicationRecord
  belongs_to :user
  has_many :meal_entries, dependent: :destroy
  has_many :foods, through: :meal_entries

  validates :date, presence: true
  validates :meal_type, presence: true, inclusion: { in: %w[breakfast lunch dinner snack] }

  scope :for_date, ->(date) { where(date: date) }
  scope :for_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  def total_nutrition
    meal_entries.includes(:food).map(&:calculated_nutrition).reduce do |sum, nutrition|
      sum.merge(nutrition) { |_, v1, v2| v1 + v2 }
    end || {}
  end
end
```

### MealEntry Model

```ruby
# app/models/meal_entry.rb
class MealEntry < ApplicationRecord
  belongs_to :meal
  belongs_to :food

  validates :servings, presence: true, numericality: { greater_than: 0 }

  def calculated_nutrition
    nutrition = food.nutrition
    nutrition.transform_values { |v| v * servings }
  end
end
```

---

## Queries & Performance

### Common Query Patterns

**Get meals for a date:**
```ruby
Meal.includes(meal_entries: :food)
    .where(user_id: user.id, date: date)
    .order(created_at: :asc)
```

**Search foods efficiently:**
```ruby
Food.search("chicken breast", user: current_user)
    .limit(20)
```

**Daily nutrition summary:**
```ruby
meals = user.meals
            .includes(meal_entries: :food)
            .for_date(date)

total_nutrition = meals.flat_map(&:meal_entries)
                       .map(&:calculated_nutrition)
                       .reduce { |sum, n| sum.merge(n) { |_, v1, v2| v1 + v2 } }
```

### Performance Optimization

1. **Always use includes for N+1 prevention**
2. **Index frequently queried columns**
3. **Use JSONB for flexible nutrition data**
4. **Composite index on (user_id, date) for meal queries**
5. **Full-text search index on food names**

---

## Seeds

```ruby
# db/seeds.rb
# Create test user
user = User.create!(
  email: 'test@example.com',
  password: 'password123',
  name: 'Test User',
  date_of_birth: '1990-01-15',
  gender: 'male',
  height_cm: 175,
  weight_kg: 75,
  activity_level: 'moderate',
  goals: {
    dailyCalories: 2200,
    proteinGrams: 165,
    carbsGrams: 220,
    fatGrams: 73
  }
)

# Sample USDA foods
Food.create!([
  {
    fdc_id: 171688,
    name: 'Apple, raw',
    serving_size: 182,
    serving_unit: 'g',
    nutrition: {
      calories: 95,
      proteinG: 0.5,
      carbsG: 25.1,
      fatG: 0.3,
      fiberG: 4.4
    },
    is_custom: false
  },
  # Add more foods...
])

puts "Seeds created: #{User.count} users, #{Food.count} foods"
```
