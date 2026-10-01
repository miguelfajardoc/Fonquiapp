## 1. Dependency and schema

- [x] 1.1 Run `bundle add pagy` (pin the resolved major in the Gemfile) and wire it per that major's README (`include Pagy::Method` in `ApplicationController` on Pagy 43+, or `Pagy::Backend`/`Pagy::Frontend` on older majors; overflow set to the last page); verify `bin/rails runner "puts Pagy::VERSION"` prints the version
- [x] 1.2 Generate a migration that deletes all `daily_product_orders` rows, then `add_reference :daily_product_orders, :route, null: false, foreign_key: true` and `add_index :daily_product_orders, [:route_id, :day]` (the `down` method drops the reference and says deleted rows are not restored); verify with `bin/rails db:migrate` and `bin/rails db:rollback && bin/rails db:migrate`, then confirm `db/schema.rb` shows `route_id` NOT NULL with its FK and indexes

## 2. Models

- [x] 2.1 Add `belongs_to :route` to `app/models/daily_product_order.rb` and `has_many :daily_product_orders, dependent: :restrict_with_error` to `app/models/route.rb`
- [x] 2.2 Update `spec/factories/daily_product_orders.rb` so the route defaults to one in the same zone (`route { association :route, zone: zone }`); verify `bundle exec rspec spec/models/daily_product_order_spec.rb` passes
- [x] 2.3 Extend `spec/models/daily_product_order_spec.rb` (rejected without a route; rejected with a non-existent `route_id`) and `spec/models/route_spec.rb` (a route referenced by a daily product order is not destroyed and keeps its stops; an unreferenced route still destroys its stops), per the `product-ordering` and `route-planning` delta specs; verify both files pass

## 3. Generation service

- [x] 3.1 Change `app/services/daily_product_order_generation.rb` to `initialize(route:, day: Date.current)`: limit defaults and `pending` pending products to the zone of `route` and `client_id IN route.route_stops.pluck(:client_id)`, replace only `DailyProductOrder.where(route:, day:)`, and create records with `zone: route.zone, route:`
- [x] 3.2 Rewrite `spec/services/daily_product_order_generation_spec.rb` around `route:` to cover every scenario of "Route-scoped batch generation" and "Regenerating a route on the same day replaces its batch" (stop-only inclusion, other-zone exclusion, delivered/canceled ignored, zero totals skipped, a client on two routes counted in both, regenerating replaces only that route+day, other days and other routes unaffected); verify the file passes

## 4. Consolidation service

- [x] 4.1 Change `app/services/daily_product_order_consolidation.rb` to `initialize(route:, day:)`: the client table comes from `route.route_stops.includes(:client)` in position order (no other zone clients), and batch orders are `DailyProductOrder.where(route:, day:)`; leave the pending columns, HYPERLINK, and totals logic as they are
- [x] 4.2 Rewrite `spec/services/daily_product_order_consolidation_spec.rb` around `route:` to cover the "Consolidated spreadsheet download" scenarios (rows in stop-position order, non-stop zone clients excluded, a stop client with nothing due still listed, pending columns, totals only from the route's batch, totals reflect the batch rather than live data); verify the file passes

## 5. Controller, views, and locales

- [x] 5.1 In `DailyProductOrdersController#index`, load `@routes` for the optional `params[:zone_id]`, and replace `load_batches` with the grouped/ordered SQL relation from design.md (decision 5) paginated by Pagy at 20 per page
- [x] 5.2 In `#generate`, look up the route by `route_id` within `zone_id`: a blank zone shows `missing_zone`, a missing or mismatched route shows the new `missing_route`, and success calls `DailyProductOrderGeneration.new(route:)` with a notice naming the zone and the route
- [x] 5.3 In `#consolidated`, take `route_id` + `day`, call `DailyProductOrderConsolidation.new(route:, day:)`, and name the file `consolidado_<zone>_<route>_<YYYY-MM-DD>.xlsx`
- [x] 5.4 Update `app/views/daily_product_orders/index.html.erb`: the zone select keeps `params[:zone_id]` selected and is wired to `client-zone-filter#reload`; add a "Ruta" select (`name="route_id"`, placeholder + `@routes`) inside `turbo_frame_tag "route_select"` as the controller's frame target; add a "Ruta" table column (day, zone, route, action); the download link uses `route_id` + `day`; render the Pagy nav below the table only when there is more than one page, styled with the existing Tailwind tokens
- [x] 5.5 Add the `es.yml` strings: `route_label`, `route_placeholder`, `table_route`, `generate.missing_route`, the updated `generate.generated` (zone + route), and `routes.flash.delete_blocked`
- [x] 5.6 Make `RoutesController#destroy` follow `ZonesController#destroy`: on failure, redirect to `routes_path` with `alert: t("routes.flash.delete_blocked")`

## 6. Request specs

- [x] 6.1 Update `spec/requests/daily_product_orders_spec.rb`: index lists one row per day+route showing zone and route names, ordered newest first; `index?zone_id=` renders only that zone's routes inside the `route_select` frame; the download link carries `route_id` and `day`; generate without a zone and without a route both redirect with an error and create nothing; generate with a valid route creates that route's batch; consolidated by `route_id` returns an xlsx with the new filename; with 25 batches page 1 shows 20 rows plus pagination controls and page 2 shows 5; with 3 batches no pagination controls appear. Verify the file passes
- [x] 6.2 Add to `spec/requests/routes_spec.rb`: deleting a route referenced by a daily product order keeps the route and its stops and redirects to the index with the `delete_blocked` alert; verify the file passes

## 7. Verification

- [x] 7.1 Run the full suite `bundle exec rspec` and confirm 0 failures (fix any other spec that builds `DailyProductOrder` or calls the services with `zone:`)
- [x] 7.2 Run `bin/rails db:seed` twice on the migrated database and confirm both runs finish without errors (seeds create no daily product orders and never delete routes, so no seed change is expected; adjust only if a run fails)
- [x] 7.3 In the running app, open `/daily_product_orders`, change the zone and check that the route select reloads with only that zone's routes and nothing selected, generate a route, check the new row shows its route, download the xlsx and check the clients follow the route's stop order, then try to delete that route from `/routes` and check the error message appears
