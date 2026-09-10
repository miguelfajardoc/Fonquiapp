class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :address
      t.string :url
      t.string :phone
      t.references :zone, null: false, foreign_key: true

      t.timestamps
    end
  end
end
