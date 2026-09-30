class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.string :name, null: false
      t.references :zone, null: false, foreign_key: true

      t.timestamps
    end

    add_index :routes, %i[zone_id name], unique: true
  end
end
