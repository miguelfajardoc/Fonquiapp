## Context

See proposal.md (Why) for the motivation. This section covers only the
current state that shapes the approach.

- `daily_product_orders` has `zone_id`, `client_id`, `product_id`, `quantity`,
  `day`, and no route reference. A "batch" is an implicit grouping, not a
  table: it is the distinct `(day, zone_id)` pairs, built in Ruby by
  `DailyProductOrdersController#load_batches` and sorted in memory.
- `DailyProductOrderGeneration.new(zone:, day: Date.current)` sums
  `DefaultProductQuantity` and `pending` `PendingProduct` for the whole zone.
  It replaces the zone+day batch with `delete_all` + `create!` inside a
  transaction.
- `DailyProductOrderConsolidation.new(zone:, day:)` builds the xlsx (caxlsx).
  The client table is `Client.where(zone:).order(:name)`. The product totals
  come from the zone+day batch.
- `Route has_many :route_stops, -> { order(:position) }` (acts_as_list,
  scoped per route). A client may be a stop on several routes of its zone.
  The seeds put every client on both routes of its zone.
- The app already uses a zone-dependent Turbo Frame pattern:
  `client_zone_filter_controller.js` reloads a target frame from the current
  page URL with `zone_id` swapped in (used by the default product quantity
  form).
- Zones and clients already handle restricted deletes in their controllers
  (`if destroy ... else redirect with alert`). `RoutesController#destroy`
  does not, because nothing restricts route deletion today.
- No pagination library is installed.

## Goals / Non-Goals

**Goals:**
- A batch is identified by `(day, route)`. Zone is still stored on each row,
  copied from the route, so existing zone-based integrity and the listing's
  zone column keep working.
- Generation and consolidation take a route and derive the zone and client
  set from it.
- The batch query runs in SQL (grouped, ordered) so Pagy can paginate it.

**Non-Goals:**
- No `route_id` on `default_product_quantities` or `pending_products`
  (explicitly deferred by the user).
- No de-duplication across routes: a client on two routes gets their defaults
  and pending items in both routes' batches (see Risks).
- No change to the pending-items columns of the xlsx. They are still read
  live at download time, as today.
- No model-level validation that `daily_product_order.zone == route.zone`.
  The only writer is the generation service, which sets both from the route.

## Decisions

### 1. Keep `zone_id` on `daily_product_orders` and add a required `route_id`

Migration: `DailyProductOrder.delete_all` (via SQL `DELETE`), then
`add_reference :daily_product_orders, :route, null: false, foreign_key: true`
(it is indexed by default). Then add a composite index
`[:route_id, :day]` for the replace-batch delete and the consolidation
lookup. The `down` method removes the reference. Deleted rows are not
restored, which is acceptable because they hold no real data.

- Model: `DailyProductOrder belongs_to :route`. `Route has_many
  :daily_product_orders, dependent: :restrict_with_error`, which makes the
  `route-planning` delete rule hold even through the console.
- *Alternative*: drop `zone_id` and derive it through the route. Rejected
  because it would also change `Zone has_many :daily_product_orders`
  integrity, the `product-ordering` spec, and every factory and spec that
  passes `zone:`, all for no user-visible gain.

### 2. Services take `route:`

- `DailyProductOrderGeneration.new(route:, day: Date.current)`:
  - `client_ids = route.route_stops.pluck(:client_id)`
  - defaults: `DefaultProductQuantity.where(zone: route.zone, client_id: client_ids)`
  - pending: `PendingProduct.where(zone: route.zone, client_id: client_ids, state: :pending)`
  - replace: `DailyProductOrder.where(route:, day:).delete_all`, then
    `create!(zone: route.zone, route:, ...)` in the same transaction.
- `DailyProductOrderConsolidation.new(route:, day:)`:
  - Clients: `route.route_stops.includes(:client).map(&:client)`. These come
    in `position` order through the association scope.
  - Batch orders: `DailyProductOrder.where(route:, day:)`.
  - The rest (pending columns, HYPERLINK, product totals) is unchanged.
- *Alternative*: keep `zone:` and add `route:`. Rejected because the route
  already determines the zone, and two arguments could disagree.

### 3. Route select on the index uses the existing zone-filter frame

- `index` reads an optional `params[:zone_id]` and loads
  `@routes = Route.where(zone_id: params[:zone_id]).order(:name)`, or none
  if there is no zone. The generate form's zone `<select>` keeps the
  selected zone and fires `change->client-zone-filter#reload`. The route
  `<select name="route_id">` sits inside
  `turbo_frame_tag "route_select"` (the `frame` target).
- When the zone changes, Turbo re-fetches `/daily_product_orders?zone_id=X`
  and swaps only the frame. The new frame has no selection, so the route is
  cleared automatically, which satisfies the spec's "clears any previously
  chosen route".
- `client_zone_filter_controller.js` is reused unchanged. Its behavior
  ("reload frame from current URL with zone_id") is generic. Renaming it to
  `zone_filter` is optional cleanup and not required.
- *Alternative*: a dedicated `route_options` endpoint returning `<option>`
  tags plus a new Stimulus controller, like `routes/client_options`.
  Rejected because it adds a route and JS for something the frame pattern
  already does.

### 4. Controller params

- `generate`: requires `route_id`. If `zone_id` is blank, show
  `missing_zone`. If the route is not found, show `missing_route`. The route
  is looked up within the zone
  (`Route.find_by(id: params[:route_id], zone_id: params[:zone_id])`) so a
  stale route from another zone is rejected instead of silently used. The
  success notice names the zone and the route.
- `consolidated`: takes `route_id` and `day`
  (`Route.find(params.expect(:route_id))`). The filename becomes
  `consolidado_<zone>_<route>_<YYYY-MM-DD>.xlsx` (parameterized). The
  download link in each row passes `route_id` and `day` and no longer passes
  `zone_id`.

### 5. Batch listing in SQL, paginated with Pagy

```ruby
DailyProductOrder
  .joins(:zone, :route)
  .group(:day, :zone_id, :route_id, "zones.name", "routes.name")
  .order(day: :desc).order("zones.name ASC, routes.name ASC")
  .select(:day, :zone_id, :route_id,
          "zones.name AS zone_name", "routes.name AS route_name")
```

- Paginate with Pagy at 20 items per page. Pagy's offset paginator counts a
  grouped relation correctly (the `count(:all)` Hash becomes its size). A
  request spec with more than 20 batches covers this.
- The view reads `batch.day`, `batch.zone_name`, `batch.route_name`, and
  `batch.route_id`. The in-memory `load_batches` is removed.
- Add the `pagy` gem at its current release, and use that major version's
  API: `include Pagy::Method` + `pagy(:offset, scope, limit: 20)` +
  `@pagy.series_nav` on Pagy 43+, or `Pagy::Backend` / `pagy_nav` on older
  majors. Render the nav below the table only when `@pagy.pages > 1`. Style
  it with existing Tailwind tokens. Pagy 43 has no `:last_page` overflow
  option. A page beyond the last one renders as an empty page (the "no
  batches" row) instead of raising an error. Installed version: Pagy 43.6
  (`Pagy::Method` in `ApplicationController`, `Pagy::OPTIONS[:limit] = 20`
  in an initializer, and `Pagy::I18n.locale` set per request so the nav
  uses Pagy's bundled `es` labels).
- *Alternative*: hand-rolled limit/offset. The user chose Pagy.

### 6. Restricted route delete

`RoutesController#destroy` follows `ZonesController#destroy`. On failure it
redirects to `routes_path` with the fixed alert
`t("routes.flash.delete_blocked")` ("No se puede eliminar la ruta porque
tiene órdenes diarias generadas."). It does not use
`errors.full_messages`, because `es.yml` has no
`restrict_dependent_destroy` translation, and adding one globally would
change zone and client messages outside this change.

### 7. Tests and seeds

- Factory: `daily_product_order` gets `route { association :route, zone: zone }`
  so the route and zone agree by default. Specs that pass `zone:` still work.
- Rewrite the service specs around `route:`. Cover stop-only inclusion,
  position ordering, route-scoped replace, a client on two routes, and
  route-only totals.
- Request specs cover the route frame on `index?zone_id=`, generate without a
  zone or route, consolidated by `route_id`, pagination, and the blocked
  route delete.
- Model specs: `route` is required on `DailyProductOrder`, and `Route` cannot
  be destroyed while referenced.
- Seeds create no `DailyProductOrder`, and they never delete routes (only
  route stops), so they need no change. Confirm by running
  `bin/rails db:seed` twice after the migration.

## Risks / Trade-offs

- [A client on several routes of a zone gets defaults and pending items in
  each route's batch. This is intended: routes that share a client never run
  on the same day, and that is managed outside the app by choosing which
  route to generate.] → Nothing in the app prevents generating both routes
  for the same day. If staff do, the two pick sheets together double-count
  that client. Pending items also stay `pending` after generation, as they
  already do with zone generation, so they reappear in later batches until
  someone marks them delivered.
- [The migration deletes all existing daily product orders.] → The user
  confirmed the data does not matter. The irreversible `down` is documented
  in the migration.
- [Pagy's API changed between majors (43 vs. 9).] → Pin the version in the
  Gemfile at install time and follow that version's README. Only one
  controller and one view use it.
- [Once a route has been generated even once, it can never be deleted,
  because batches cannot be removed from the UI.] → This is accepted for
  now and matches how zones and clients behave. A route can still be
  renamed or have its stops edited. How to retire or delete routes that have
  history will be decided in a separate change.

## Migration Plan

1. `bundle add pagy`. Run the migration (delete rows, add `route_id` NOT NULL
   FK, add `[route_id, day]` index).
2. Deploy code and migration together. Old daily product orders are gone, so
   staff regenerate today's batches per route.
3. Rollback: run the `down` migration (drops the column) and revert the code.
   Deleted batches are not restored. Regenerate them per zone.
