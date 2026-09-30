# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_30_020102) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "clients", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.string "url"
    t.bigint "zone_id", null: false
    t.index ["zone_id"], name: "index_clients_on_zone_id"
  end

  create_table "daily_product_orders", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.date "day", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["client_id"], name: "index_daily_product_orders_on_client_id"
    t.index ["product_id"], name: "index_daily_product_orders_on_product_id"
    t.index ["zone_id"], name: "index_daily_product_orders_on_zone_id"
  end

  create_table "default_product_quantities", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["client_id"], name: "index_default_product_quantities_on_client_id"
    t.index ["product_id", "client_id", "zone_id"], name: "idx_on_product_id_client_id_zone_id_64c758f1b9", unique: true
    t.index ["product_id"], name: "index_default_product_quantities_on_product_id"
    t.index ["zone_id"], name: "index_default_product_quantities_on_zone_id"
  end

  create_table "pending_products", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "quantity", null: false
    t.integer "state", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["client_id"], name: "index_pending_products_on_client_id"
    t.index ["product_id"], name: "index_pending_products_on_product_id"
    t.index ["zone_id"], name: "index_pending_products_on_zone_id"
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_products_on_name", unique: true
  end

  create_table "route_stops", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.datetime "created_at", null: false
    t.integer "position"
    t.bigint "route_id", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_route_stops_on_client_id"
    t.index ["route_id", "client_id"], name: "index_route_stops_on_route_id_and_client_id", unique: true
    t.index ["route_id", "position"], name: "index_route_stops_on_route_id_and_position"
    t.index ["route_id"], name: "index_route_stops_on_route_id"
  end

  create_table "routes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "zone_id", null: false
    t.index ["zone_id", "name"], name: "index_routes_on_zone_id_and_name", unique: true
    t.index ["zone_id"], name: "index_routes_on_zone_id"
  end

  create_table "zones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_zones_on_name", unique: true
  end

  add_foreign_key "clients", "zones"
  add_foreign_key "daily_product_orders", "clients"
  add_foreign_key "daily_product_orders", "products"
  add_foreign_key "daily_product_orders", "zones"
  add_foreign_key "default_product_quantities", "clients"
  add_foreign_key "default_product_quantities", "products"
  add_foreign_key "default_product_quantities", "zones"
  add_foreign_key "pending_products", "clients"
  add_foreign_key "pending_products", "products"
  add_foreign_key "pending_products", "zones"
  add_foreign_key "route_stops", "clients"
  add_foreign_key "route_stops", "routes"
  add_foreign_key "routes", "zones"
end
