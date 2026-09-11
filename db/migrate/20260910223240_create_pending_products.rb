class CreatePendingProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_products do |t|
      t.integer :quantity, null: false
      t.integer :state, null: false, default: 0
      t.references :product, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
