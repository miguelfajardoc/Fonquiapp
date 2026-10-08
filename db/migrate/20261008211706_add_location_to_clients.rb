class AddLocationToClients < ActiveRecord::Migration[8.1]
  def change
    change_table :clients, bulk: true do |t|
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
    end
  end
end
