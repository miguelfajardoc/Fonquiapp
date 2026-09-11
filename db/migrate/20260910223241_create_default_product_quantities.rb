class CreateDefaultProductQuantities < ActiveRecord::Migration[8.1]
  def change
    create_table :default_product_quantities do |t|
      t.references :product, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end

    add_index :default_product_quantities, %i[product_id client_id zone_id], unique: true
  end
end
