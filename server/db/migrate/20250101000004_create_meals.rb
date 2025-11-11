class CreateMeals < ActiveRecord::Migration[7.1]
  def change
    create_table :meals, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.date :date, null: false
      t.string :meal_type, null: false, limit: 20
      t.string :name, limit: 255
      t.text :notes
      t.text :image_url

      t.timestamps
    end

    add_index :meals, [:user_id, :date], order: { date: :desc }
    add_index :meals, :user_id
    add_index :meals, :date
    add_foreign_key :meals, :users, on_delete: :cascade

    add_check_constraint :meals, "meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')", name: 'meal_type_check'
  end
end
