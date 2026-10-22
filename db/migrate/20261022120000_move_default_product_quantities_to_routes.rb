# Defaults now belong to a route+product, and daily orders no longer reference a client. Existing rows of both
# tables are discarded: they cannot be mapped to the new shape and the data is not needed.
class MoveDefaultProductQuantitiesToRoutes < ActiveRecord::Migration[8.1]
  def up
    execute "DELETE FROM daily_product_orders"
    execute "DELETE FROM default_product_quantities"

    remove_index :default_product_quantities, %i[product_id client_id zone_id]
    remove_reference :default_product_quantities, :client, foreign_key: true, index: true
    remove_reference :default_product_quantities, :zone, foreign_key: true, index: true
    # The table was emptied above, so the NOT NULL column needs no default.
    add_reference :default_product_quantities, :route, null: false, foreign_key: true, index: true # rubocop:disable Rails/NotNullColumn
    add_index :default_product_quantities, %i[route_id product_id], unique: true

    remove_reference :daily_product_orders, :client, foreign_key: true, index: true
  end

  # The old columns come back nullable and empty: the discarded rows cannot be restored.
  def down
    add_reference :daily_product_orders, :client, foreign_key: true, index: true

    remove_index :default_product_quantities, %i[route_id product_id]
    remove_reference :default_product_quantities, :route, foreign_key: true, index: true
    add_reference :default_product_quantities, :zone, foreign_key: true, index: true
    add_reference :default_product_quantities, :client, foreign_key: true, index: true
    add_index :default_product_quantities, %i[product_id client_id zone_id], unique: true
  end
end
