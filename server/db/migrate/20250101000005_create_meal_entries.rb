class CreateMealEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :meal_entries, id: :uuid do |t|
      t.uuid :meal_id, null: false
      t.uuid :food_id, null: false
      t.decimal :servings, precision: 10, scale: 2, null: false, default: 1.0

      t.timestamps
    end

    add_index :meal_entries, :meal_id
    add_index :meal_entries, :food_id
    add_foreign_key :meal_entries, :meals, on_delete: :cascade
    add_foreign_key :meal_entries, :foods, on_delete: :restrict

    add_check_constraint :meal_entries, "servings > 0", name: 'servings_positive'
  end
end
