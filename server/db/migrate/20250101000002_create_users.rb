class CreateUsers < ActiveRecord::Migration[7.1]
  def change
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
