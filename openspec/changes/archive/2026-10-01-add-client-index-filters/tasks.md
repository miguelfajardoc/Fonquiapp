## 1. Database

- [x] 1.1 Generate a migration with `enable_extension "unaccent"`. Verify with `bin/rails db:migrate`, then `bin/rails db:rollback && bin/rails db:migrate`. Check that `db/schema.rb` lists `unaccent`, and that `bin/rails runner 'puts ActiveRecord::Base.connection.select_value("select unaccent(%q(San José))")'` prints `San Jose`. Run `RAILS_ENV=test bin/rails db:prepare`.

## 2. Model filtering

- [x] 2.1 Create `app/models/concerns/filterable.rb` with `filter_by(filters)` (skips blank values and calls `filter_by_<key>` for each remaining key), per design.md decision 2
- [x] 2.2 Include `Filterable` in `Client` and add the scopes `filter_by_name` (`unaccent(clients.name) ILIKE unaccent(?)` with `sanitize_sql_like`), `filter_by_zone_id`, and `filter_by_route_id` (subquery on `route_stops.client_id`)
- [x] 2.3 Extend `spec/models/client_spec.rb` with `filter_by` cases: contains match, case- and accent-insensitive both ways ("JOSE" finds "San José", "dona" finds "Doña Rosa"), `%` and `_` matched literally, zone only, route stops only, a client on several routes returned once, combined filters, blank values ignored. Verify the file passes.

## 3. Controller

- [x] 3.1 In `ClientsController#index`: load `@zones` and `@routes` (routes of `params[:zone_id]`, none without a zone), drop `route_id` unless it belongs to `@routes`, and set `@pagy, @clients = pagy(:offset, Client.includes(:zone).filter_by(filter_params).order(:name))` with `filter_params = params.permit(:name, :zone_id, :route_id)`

## 4. JavaScript

- [x] 4.1 Create `app/javascript/controllers/auto_submit_controller.js` with `submit` (blanks the fields named in the `clear` action param, then `requestSubmit()`) and `debouncedSubmit` (300 ms), per design.md decision 5. Check that it loads with no console errors on the clients index.

## 5. Views and locales

- [x] 5.1 Extract the styled Pagy nav from `app/views/daily_product_orders/index.html.erb` into `app/views/shared/_pagination.html.erb` (renders nothing when there is one page) and render it there. Verify `bundle exec rspec spec/requests/daily_product_orders_spec.rb` still passes.
- [x] 5.2 Update `app/views/clients/index.html.erb`:
  - Add a GET filter form (`data-turbo-frame="clients"`, `data-controller="auto-submit client-zone-filter"`). It holds the name input (`input->auto-submit#debouncedSubmit`, value from params), the zone select (keeps the selected zone, `change->client-zone-filter#reload change->auto-submit#submit` with `route_id` as the clear param), and the route select in `turbo_frame_tag "client_route_filter"` (the frame target, `change->auto-submit#submit`, keeps the selected route).
  - Wrap the table, an empty-state row, and `shared/pagination` in `turbo_frame_tag "clients", data: { turbo_action: "advance" }`.
  - Keep the create button, row navigation, and delete dialog working.
- [x] 5.3 Add the `es.yml` strings under `clients.index`: `filter_name_label`, `filter_name_placeholder`, `filter_zone_label`, `filter_zone_placeholder` ("Todas las zonas"), `filter_route_label`, `filter_route_placeholder` ("Todas las rutas"), `no_results`

- [x] 5.4 Add a "Ruta" column right after "Zona" in the clients table, showing each client's route names (sorted, comma-separated, empty when none). Add `has_many :routes, through: :route_stops` to `Client` and preload `routes` in `#index` to avoid N+1. Add `table_route` to `es.yml`, and adjust the empty-state `colspan`.

- [x] 5.5 Clients index layout:
  - Remove the duplicated in-page `<h1>` title. The header already shows it through `content_for :title`.
  - Put the filter form and the "Crear cliente" button on one row, with the button aligned right.
  - Add a "Limpiar filtros" link next to the filters, pointing to `clients_path` with `data-turbo-frame="_top"` so a full visit empties every control.
  - Add `clear_filters` to `es.yml`.

## 6. Request specs

- [x] 6.1 Extend `spec/requests/clients_spec.rb` for `GET /clients`:
  - The filter form, the `clients` frame, and the `client_route_filter` frame render.
  - Filtering by `name` (including accents), by `zone_id`, and by `zone_id` + `route_id` lists only the matching clients.
  - A `route_id` from another zone is ignored.
  - The route select offers only the selected zone's routes, and none without a zone.
  - The filter values are pre-filled from params.
  - With no matches, the `no_results` message shows.
  - With 25 clients, page 1 shows 20 rows plus the pagination nav and page 2 shows 5. Pagination links keep `zone_id`. With 3 clients there is no nav.
  - Keep the existing listing example passing. Verify the file passes.
- [x] 6.2 Add a `GET /clients` request example: a client on two routes shows "Ruta 1, Ruta 2" in the column after the zone, and a client on no route shows an empty cell. Verify the file passes.
- [x] 6.3 Add `GET /clients` request examples: there is no in-page `<h1>` title, the "Crear cliente" link sits in the same row as the filter form, and a "Limpiar filtros" link points to `/clients` with no query and `data-turbo-frame="_top"`. Verify the file passes.

## 7. Verification

- [x] 7.1 Run `bundle exec rspec` and `bin/rubocop` on the changed files. Confirm 0 failures and no new offenses.
- [x] 7.2 In the browser at `/clients`:
  - Type in the name box and check that the table updates after a short pause without losing focus, and that "jose" finds a client with "José".
  - Pick a zone and check that the route select fills with that zone's routes.
  - Pick a route and check that the table narrows.
  - Change the zone and check that the route clears and the table shows the new zone.
  - Reload and check that the filters persist. Use the back button.
  - Open page 2 with a filter active.
  - Check that the "Ruta" column shows each client's routes after "Zona".
  - Check that "Limpiar filtros" empties every filter and the table, and that "Crear cliente" is on the filters' row.
  - Click a row to open the client, then delete a client from the filtered list.
