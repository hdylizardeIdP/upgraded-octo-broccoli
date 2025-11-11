class CreateWaterIntakes < ActiveRecord::Migration[7.1]
  def change
    create_table :water_intakes, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.date :date, null: false
      t.integer :amount_ml, null: false
      t.datetime :time, null: false

      t.timestamps
    end

    add_index :water_intakes, [:user_id, :date], order: { date: :desc }
    add_foreign_key :water_intakes, :users, on_delete: :cascade

    add_check_constraint :water_intakes, "amount_ml > 0", name: 'amount_positive'
  end
end
