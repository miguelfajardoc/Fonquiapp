class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :products, :name, unique: true
  end
end
