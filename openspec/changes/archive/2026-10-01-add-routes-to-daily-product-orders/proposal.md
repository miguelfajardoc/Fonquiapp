## Why

Daily product orders are generated per zone today, but deliveries are actually
run per route: a driver follows one route's ordered list of client stops (see
`route-planning`). Now that routes and their stop order exist, the daily batch
and its consolidated pick sheet need to be generated and laid out per route,
so the sheet follows the driver's visiting order and only covers that route's
clients.

## What Changes

- Add a required `route_id` reference to `daily_product_orders` (NOT NULL,
  foreign key enforced by the datastore). Existing daily product order rows
  are discarded by the migration; there is no production data to keep.
  **BREAKING** for any code creating a `DailyProductOrder` without a route.
- `DefaultProductQuantity` and `PendingProduct` are **not** changed: they stay
  keyed by zone + client + product. A route's clients are derived from its
  route stops.
- Batch generation becomes route-scoped: the daily product order page gets a
  route select, filtered to the routes of the selected zone (reloaded when the
  zone changes). Generating computes totals (default quantity + `pending`
  pending products) only for the clients that are stops of the chosen route,
  and stamps every resulting record with that route. A route is required to
  generate.
- Regenerating the same route on the same day replaces only that route's
  batch; other routes of the same zone are untouched.
- The batch listing groups by day + zone + route, shows the route name in a
  new column, and is paginated with the Pagy gem (new dependency).
- The consolidated spreadsheet is per batch (day + route): its client table
  lists only the route's stop clients, ordered by their route stop
  `position`, instead of every client in the zone ordered by name. The
  product totals table sums only that route's batch.
- A route that is referenced by any daily product order can no longer be
  deleted; the route index shows an error instead of deleting it (same
  behavior as zones and clients).
- Update factories, specs, and seeds so everything passes with the required
  route reference.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `daily-product-order-management`: generation, regeneration, batch listing,
  and the consolidated spreadsheet become route-scoped; listing gains a route
  column and pagination.
- `product-ordering`: the daily product order record requires a route
  reference.
- `route-planning`: a route referenced by a daily product order cannot be
  deleted.
- `route-management`: route deletion reports an error when the route is
  referenced by daily product orders.

## Impact

- **Database**: new migration adding `route_id` (NOT NULL, FK, indexed) to
  `daily_product_orders`, deleting existing rows first.
- **Models**: `DailyProductOrder` (`belongs_to :route`), `Route`
  (`has_many :daily_product_orders, dependent: :restrict_with_error`).
- **Services**: `DailyProductOrderGeneration` (takes a route; restricted to the
  route's stop clients; replaces only that route's day batch),
  `DailyProductOrderConsolidation` (takes a route; client table from route
  stops in position order).
- **Controllers/views**: `DailyProductOrdersController` (`generate`,
  `consolidated`, `index` with Pagy), `daily_product_orders/index.html.erb`
  (route select in a Turbo Frame, route column, pagination nav),
  `RoutesController#destroy` (handle restricted delete), `es.yml` strings.
- **Dependencies**: adds the `pagy` gem.
- **Tests/seeds**: `daily_product_orders` factory, model/service/request
  specs for daily product orders and routes, `db/seeds.rb` (verified; it
  currently seeds no daily product orders).
