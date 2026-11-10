## 1. Shared filter pieces

- [x] 1.1 Make `Route` `Filterable` with `filter_by_zone_id`, `filter_by_route_id` and `filter_by_client_id` (subquery on `route_stops`); verify new examples in `spec/models/route_spec.rb` pass: each filter alone, combined zone + client, a route with several stops of the client listed once, a blank filter not restricting
- [x] 1.2 Add the `RouteFilterOptions` controller concern: `route_filter_options(zone_id)` returns all routes ordered by zone name then route name, or only that zone's routes when a zone is given; verify with a request-level check in task 3.1 (every route listed with no zone)

## 2. Route filter selects on the other indexes

- [x] 2.1 `ClientsController#index`: build `@routes` with `route_filter_options(params[:zone_id].presence)`; update `spec/requests/clients_spec.rb` for "Route choices follow the selected zone" (all routes with no zone) and add "Route filter without a zone"; verify the clients request specs pass
- [x] 2.2 `DefaultProductQuantitiesController#load_filters`: build `@filter_routes` with `route_filter_options`, keeping the "drop a route outside the options" guard; update/add the `spec/requests/default_product_quantities_spec.rb` examples for all routes with no zone and "Route filter without a zone"; verify they pass and the creation-form route select still offers no routes without a zone
- [x] 2.3 `DailyProductOrdersController#load_table_filters`: same change for `@filter_routes`, leaving the generation `@routes` as is; replace "offers no table routes until a table zone is selected" in `spec/requests/daily_product_orders_spec.rb` with the all-routes behavior, add "Table route filter without a zone", keep "offers no routes until a zone is selected" for the generation select; verify the daily order request specs pass

## 3. Route index filters and pagination

- [x] 3.1 `RoutesController#index`: load `@zones`, `@filter_routes` via `route_filter_options`, validated `route_id`, `client_id` and a filter object (`client_id` + `client`) for the combobox; scope `Route.joins(:zone).preload(:zone, route_stops: :client).filter_by(filters).order("zones.name", :name)` paginated with `pagy(:offset, …)`; verify new `spec/requests/routes_spec.rb` examples for zone, route, route-without-zone, route-outside-zone ignored, client, combined filters, zone-then-name order, and 25 routes over two pages with filters kept
- [x] 3.2 Update `routes/index.html.erb`: filter form (zone select, route select in the `route_route_filter` frame, client combobox on `client_options_pending_products_path` with selection/removal → `auto-submit#submit`, `shared/clear_filters`) next to the "Nueva ruta" button; table, `no_results` row and `shared/_pagination` inside `turbo_frame_tag "routes"` with `turbo_action: "advance"`; add `routes.index` filter/no-results keys in `config/locales/es.yml`; verify request specs for the filter controls, the empty-state message, no pagination for 3 routes, and the chosen client's **name** prefilled in the combobox after a reload with `client_id`
- [x] 3.3 Check the route index in the headless browser: choosing a zone narrows and clears the route select; with no zone, all routes are offered and choosing one filters without changing the zone; picking a client filters the list (and removing it clears the filter); reloading keeps filters and shows the client name; paging keeps filters; "Limpiar filtros" empties everything; edit and delete still work from a filtered list
- [x] 3.4 In the headless browser, check that the client, default quantity and daily order indexes offer all routes with no zone, that a route alone filters the list, and that the default quantity creation form and the daily order generation select still wait for a zone

## 4. Wrap-up

- [x] 4.1 Run the full suite and linters; verify `bundle exec rspec` has 0 failures and `bin/rubocop` reports no offenses
