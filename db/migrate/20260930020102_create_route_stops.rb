class CreateRouteStops < ActiveRecord::Migration[8.1]
  def change
    create_table :route_stops do |t|
      t.references :route, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.integer :position

      t.timestamps
    end

    add_index :route_stops, %i[route_id client_id], unique: true
    add_index :route_stops, %i[route_id position]
  end
end
