class CreateFoods < ActiveRecord::Migration[7.1]
  def change
    create_table :foods, id: :uuid do |t|
      t.integer :fdc_id
      t.string :name, null: false, limit: 500
      t.string :brand, limit: 255
      t.decimal :serving_size, precision: 10, scale: 2, null: false
      t.string :serving_unit, null: false, limit: 50
      t.jsonb :nutrition, null: false, default: {}
      t.string :barcode, limit: 50
      t.text :image_url
      t.boolean :is_custom, default: false
      t.uuid :user_id

      t.timestamps
    end

    add_index :foods, :fdc_id, unique: true
    add_index :foods, :name
    add_index :foods, :barcode
    add_index :foods, :user_id
    add_index :foods, :is_custom
    add_foreign_key :foods, :users, on_delete: :cascade
  end
end
