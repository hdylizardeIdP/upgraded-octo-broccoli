# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_01_01_000007) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "foods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.integer "fdc_id"
    t.string "name", limit: 500, null: false
    t.string "brand", limit: 255
    t.decimal "serving_size", precision: 10, scale: 2, null: false
    t.string "serving_unit", limit: 50, null: false
    t.jsonb "nutrition", default: {}, null: false
    t.string "barcode", limit: 50
    t.text "image_url"
    t.boolean "is_custom", default: false
    t.uuid "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["barcode"], name: "index_foods_on_barcode"
    t.index ["fdc_id"], name: "index_foods_on_fdc_id", unique: true
    t.index ["is_custom"], name: "index_foods_on_is_custom"
    t.index ["name"], name: "index_foods_on_name"
    t.index ["user_id"], name: "index_foods_on_user_id"
  end

  create_table "meal_entries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "meal_id", null: false
    t.uuid "food_id", null: false
    t.decimal "servings", precision: 10, scale: 2, default: "1.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["food_id"], name: "index_meal_entries_on_food_id"
    t.index ["meal_id"], name: "index_meal_entries_on_meal_id"
    t.check_constraint "servings > 0::numeric", name: "servings_positive"
  end

  create_table "meals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.date "date", null: false
    t.string "meal_type", limit: 20, null: false
    t.string "name", limit: 255
    t.text "notes"
    t.text "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_meals_on_date"
    t.index ["user_id", "date"], name: "index_meals_on_user_id_and_date", order: { date: :desc }
    t.index ["user_id"], name: "index_meals_on_user_id"
    t.check_constraint "meal_type::text = ANY (ARRAY['breakfast'::character varying, 'lunch'::character varying, 'dinner'::character varying, 'snack'::character varying]::text[])", name: "meal_type_check"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "name", null: false
    t.date "date_of_birth"
    t.string "gender"
    t.integer "height_cm"
    t.decimal "weight_kg", precision: 5, scale: 2
    t.string "activity_level"
    t.jsonb "goals", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "water_intakes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.date "date", null: false
    t.integer "amount_ml", null: false
    t.datetime "time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_water_intakes_on_user_id_and_date", order: { date: :desc }
    t.check_constraint "amount_ml > 0", name: "amount_positive"
  end

  create_table "weights", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.date "date", null: false
    t.decimal "weight_kg", precision: 5, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "date"], name: "index_weights_on_user_id_and_date", unique: true, order: { date: :desc }
    t.check_constraint "weight_kg > 0::numeric", name: "weight_positive"
  end

  add_foreign_key "foods", "users", on_delete: :cascade
  add_foreign_key "meal_entries", "foods", on_delete: :restrict
  add_foreign_key "meal_entries", "meals", on_delete: :cascade
  add_foreign_key "meals", "users", on_delete: :cascade
  add_foreign_key "water_intakes", "users", on_delete: :cascade
  add_foreign_key "weights", "users", on_delete: :cascade
end
