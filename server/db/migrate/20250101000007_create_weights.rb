class CreateWeights < ActiveRecord::Migration[7.1]
  def change
    create_table :weights, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.date :date, null: false
      t.decimal :weight_kg, precision: 5, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    add_index :weights, [:user_id, :date], unique: true, order: { date: :desc }
    add_foreign_key :weights, :users, on_delete: :cascade

    add_check_constraint :weights, "weight_kg > 0", name: 'weight_positive'
  end
end
