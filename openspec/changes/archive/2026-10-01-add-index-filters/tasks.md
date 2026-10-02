## 1. Shared building blocks

- [x] 1.1 Add `where_unaccent_contains(column_sql, text)` to `app/models/concerns/filterable.rb` (design.md decision 1) and refactor `Client.filter_by_name` onto it. Verify `bundle exec rspec spec/models/client_spec.rb` still passes.
- [x] 1.2 Give `client_zone_filter_controller.js` an optional `param` value (default `zone_id`) used as the query key it sets. Verify the client and daily-order request specs still pass (default behavior unchanged).

## 2. Model scopes

- [x] 2.1 Add `Filterable` and the scopes from design.md decision 2:
  - `Product.filter_by_name`.
  - `DefaultProductQuantity.filter_by_client_name` and `filter_by_zone_id`.
  - `PendingProduct.filter_by_client_name`, `filter_by_zone_id`, and `filter_by_state`, which ignores unknown states.
  - `DailyProductOrder.filter_by_zone_id` and `filter_by_route_id`.
- [x] 2.2 Add model specs for each new scope: contains match ignoring case and accents, literal `%`, zone, state (including an unknown value being ignored), route, combined filters, and blank values ignored. Verify the model specs pass.

## 3. Productos

- [x] 3.1 In `ProductsController#index`, use `FILTER_KEYS = %i[name]`, `Product.filter_by(...).order(:name)`, and Pagy.
- [x] 3.2 In `products/index.html.erb`:
  - Remove the `<h1>`.
  - Add a top row (`mt-4`) with the name filter form (`auto-submit`, `data-turbo-frame="products"`), "Limpiar filtros" (`_top`), and the create button on the right.
  - Wrap the table, the empty-state row, and `shared/pagination` in `turbo_frame_tag "products"` (advance).
  - Add the `es.yml` strings.
- [x] 3.3 Add request specs: filter by name (accent-insensitive), no-results message, pagination with 25 records (page links keep `name`, single page shows no nav), the clear link, and no `<h1>`. Verify the file passes.

## 4. Default

- [x] 4.1 In `DefaultProductQuantitiesController#index`, use `FILTER_KEYS = %i[client_name zone_id]`, preload `:zone`, keep the client then product order, and add Pagy.
- [x] 4.2 In `default_product_quantities/index.html.erb`:
  - Remove the `<h1>`.
  - Add a top row (`mt-4`) with the client-name input, the zone select ("Todas las zonas"), "Limpiar filtros", and the create button.
  - Add a "Zona" column after "Cliente".
  - Add a frame `default_product_quantities` (advance) with the empty state and pagination.
  - Add the `es.yml` strings.
- [x] 4.3 Add request specs: client-name filter (accents), zone filter, combined filters, Zona column, no results, pagination keeping `zone_id`, the clear link, and no `<h1>`. Verify the file passes.

## 5. Pendientes

- [x] 5.1 In `PendingProductsController#index`, use `FILTER_KEYS = %i[zone_id client_name state]`, preload `:zone`, and apply the `sort` param (`oldest` → asc, otherwise desc, with an `id` tiebreaker) and Pagy.
- [x] 5.2 Add the "Zona" cell after the client in `pending_products/_row.html.erb`. Verify `toggle_state` and update stream responses still render the row (existing pending request specs pass).
- [x] 5.3 In `pending_products/index.html.erb`:
  - Remove the `<h1>`.
  - Add a top row (`mt-4`) with the zone select, the client-name input, the state select ("Todos los estados" + the three states), the sort select ("Más recientes primero" / "Más antiguos primero"), "Limpiar filtros", and the create button.
  - Add the "Zona" header.
  - Add a frame `pending_products` (advance) with the empty state and pagination.
  - Keep the confirm dialog and edit modal outside the frame.
  - Add the `es.yml` strings.
- [x] 5.4 Add request specs: each filter, combined filters, the default newest-first order and the `sort=oldest` order, Zona column, no results, pagination keeping `state` and `sort`, the clear link, and no `<h1>`. Verify the file passes.

- [x] 5.5 Default the Pendientes state filter to "Pendiente" when no `state` param is given. "Todos los estados" submits `state=all`, which applies no state filter, and the clear link returns to the default. Update request specs: default shows only pending and the select shows "Pendiente", `state=all` lists every state, and examples that need non-pending rows pass `state: "all"`.

## 6. Orden Diaria

- [x] 6.1 In `DailyProductOrdersController#index`:
  - Load `@filter_routes` for `params[:filter_zone_id]`.
  - Map `filter_zone_id` and `filter_route_id` to `filter_by(zone_id:, route_id:)`, dropping a route outside the filter zone.
  - Order batches by `MAX(daily_product_orders.created_at) DESC`, with `route_id` and `day` as tiebreakers.
- [x] 6.2 In `daily_product_orders/index.html.erb`:
  - Remove the `<h1>`. Keep the generation form at the top (`mt-4`).
  - Below it, add a bordered "Filtrar tabla" section with a GET form (`auto-submit client-zone-filter`, `param` value `filter_zone_id`, `data-turbo-frame="daily_product_orders"`). It holds a zone select (clears `filter_route_id` on change), a route select in `turbo_frame_tag "batch_route_filter"`, and "Limpiar filtros".
  - Wrap the table, the empty state, and pagination in `turbo_frame_tag "daily_product_orders"` (advance).
  - Add the `es.yml` strings.
- [x] 6.3 Update `spec/requests/daily_product_orders_spec.rb`:
  - A just-generated batch is listed first within the same day, and a regenerated batch moves to the top.
  - The zone and route table filters work, and a route from another zone is ignored.
  - `filter_zone_id` fills only the table route frame, and the generation `route_select` frame is unaffected (and the reverse).
  - Page links keep the filter params, the clear link works, there are no-results and no-`<h1>` checks, and the existing examples are adjusted to the new ordering.

  Verify the file passes.

## 7. Remaining index chrome

- [x] 7.1 In `zones/index.html.erb` and `routes/index.html.erb`, remove the `<h1>` and put the create button in a `mt-4 flex justify-end` row. In `clients/index.html.erb`, add `mt-4` to the top row. Verify the zones, routes, and clients request specs pass.

## 8. Verification

- [x] 8.1 Run `bundle exec rspec` and `bin/rubocop` on the changed Ruby files. Confirm 0 failures and no new offenses.
- [x] 8.2 In the browser:
  - On each index, check that the title shows only in the header, there is spacing below the header, and the create button sits on the filters' row.
  - Check that text filters keep focus while typing, selects apply immediately, and "Limpiar filtros" resets everything.
  - On Pendientes, check that toggling a state updates the row in place, the edit modal still works, and the sort select reorders.
  - On Orden Diaria, check that changing the generation zone does not touch the table filters and the reverse, the table route depends on the table zone, and a newly generated batch appears at the top.
