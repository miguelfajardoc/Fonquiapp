class AddRouteToDailyProductOrders < ActiveRecord::Migration[8.1]
  # Existing daily product orders have no route to backfill and hold no real
  # data, so they are discarded before route_id becomes required. Rolling
  # back drops the column but does not restore the deleted rows.
  def up
    execute "DELETE FROM daily_product_orders"

    add_reference :daily_product_orders, :route, null: false, foreign_key: true # rubocop:disable Rails/NotNullColumn -- table emptied above
    add_index :daily_product_orders, %i[route_id day]
  end

  def down
    remove_reference :daily_product_orders, :route, foreign_key: true, index: true
  end
end
