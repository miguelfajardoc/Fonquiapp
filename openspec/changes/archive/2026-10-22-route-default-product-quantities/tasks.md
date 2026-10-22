## 1. Database and models

- [x] 1.1 Add a migration that deletes all `daily_product_orders` and `default_product_quantities` rows, reshapes `default_product_quantities` (drop `client_id`/`zone_id` with FKs and indexes, add `route_id` not null with FK, unique index on `route_id+product_id`) and drops `client_id` from `daily_product_orders`, with a `down` that re-adds the old columns as nullable; verify `bin/rails db:migrate` then `db:rollback` then `db:migrate` succeed and `db/schema.rb` shows the new shape
- [x] 1.2 Update `DefaultProductQuantity` (belongs to route and product, quantity > 0, unique product per route, delegate `zone` to route, `filter_by_zone_id` via routes, `filter_by_route_id`, no client-name filter) and its factory; verify `spec/models/default_product_quantity_spec.rb`, rewritten for the "Route default product quantity record" scenarios, passes
- [x] 1.3 Update `DailyProductOrder` (no client) and its factory; verify `spec/models/daily_product_order_spec.rb`, rewritten for the "Route daily product order record" scenarios, passes
- [x] 1.4 Update associations: `Route has_many :default_product_quantities, dependent: :destroy` declared after `daily_product_orders`; remove default-quantity associations from `Client` and `Zone` and daily-order association from `Client`; verify route, client, zone and product model specs pass, including "Deleting a route deletes its default quantities" and "A route referenced by a daily product order cannot be deleted" (defaults kept)

## 2. Daily order generation and spreadsheet

- [x] 2.1 Rewrite `DailyProductOrderGeneration` to copy the route's defaults (no pending products, no client); verify `spec/services/daily_product_order_generation_spec.rb`, rewritten for "Route batch generation from defaults" and the regeneration scenarios, passes
- [x] 2.2 Remove pending product columns from `DailyProductOrderConsolidation` (client table = name, address, location per stop; product totals from the batch); verify `spec/services/daily_product_order_consolidation_spec.rb`, rewritten for "Consolidated route spreadsheet download", passes
- [x] 2.3 Update `spec/requests/daily_product_orders_spec.rb` for orders without clients (generation, grouped listing, filters, download); verify it passes

## 3. Default quantity screens

- [x] 3.1 Give `client-panel-filter` a `param` value (default `client_id`) and make it read the value from a plain select `change` event as well as combobox events; verify the pending product request specs still pass and the pending product creation panel still reloads in the headless browser
- [x] 3.2 Update `DefaultProductQuantitiesController`: index filters `zone_id`/`route_id` (route ignored outside the zone), order by zone, route, product; `new` reads `zone_id`/`route_id` and loads the route's defaults; create/update/destroy turbo streams use the route list; permit `zone_id` only for the form, not the model; remove `client_options` and its route in `config/routes.rb`; verify `bin/rails routes | grep default_product` shows no `client_options`
- [x] 3.3 Update index view and `_row` (Zona, Ruta, Producto, Cantidad, Acciones; zone select + route select in a Turbo Frame with clear-param; no client-name box) and locale keys in `config/locales/es.yml`; verify the index request specs for listing, order, filters, clear filters and pagination pass
- [x] 3.4 Update `_form` (zone select → route select frame reloaded by `client-zone-filter`, product, quantity `min: 1`) and replace the client panel partials with `_route_panel`/`_route_default_list`; verify the creation request specs ("Route default quantity creation", "Route default list on the creation page") pass
- [x] 3.5 Update `edit.html.erb` (zone and route shown as fixed values, quantity `min: 1`) and `_actions` (confirmation label "<route> / <product>"); verify the editing and deletion request specs pass
- [x] 3.6 Check the creation page and index in the headless browser: changing the zone refreshes and clears the route, choosing a route shows its defaults, creating two products in a row keeps zone and route, and edit/delete work from both the index and the route list

## 4. Sidebar

- [x] 4.1 Rework `layouts/_sidebar.html.erb`: "Rutas" hover group with "Rutas" and "Default"; "Productos", "Pendientes", "Orden Diaria" as top-level links; active state for every top-level entry (Rutas active on routes and default quantity pages) via a small class helper; rename `nav.products_default` to `nav.routes_default`; verify `spec/requests/app_shell_spec.rb`, rewritten for "Sidebar top-level entries", "Rutas submenu on hover" and "Active section highlighting", passes
- [x] 4.2 Check the sidebar in the headless browser: hovering "Rutas" reveals its submenu, "Productos" has no submenu, and the active entry is highlighted on each section

## 5. Seeds and wrap-up

- [x] 5.1 Update `db/seeds/development.rb` to create 2–4 random product defaults per route (`rand(5..30)`); verify `bin/rails db:reset` succeeds and `spec/db/seeds_spec.rb` passes
- [x] 5.2 Search for leftover references (`grep -rn "default_product_quantit" app spec db` for `client`/`zone_id` uses, and `pending` in the daily order services); verify none remain
- [x] 5.3 Run the full suite and linters (`bundle exec rspec`, `bin/rubocop`); verify both pass
- [x] 5.4 When archiving, update the Purpose of `openspec/specs/default-product-quantity-management/spec.md` (per route+product) and `openspec/specs/daily-product-order-management/spec.md` (defaults only, no pending deliveries), since deltas do not change Purpose
