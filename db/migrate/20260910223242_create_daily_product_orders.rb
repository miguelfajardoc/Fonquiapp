class CreateDailyProductOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_product_orders do |t|
      t.references :product, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :zone, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.date :day, null: false

      t.timestamps
    end
  end
end
