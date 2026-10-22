## Context

See proposal.md for the motivation. Current state that shapes the approach:

- `default_product_quantities` has `client_id`, `zone_id`, `product_id`,
  `quantity` with a unique index on `product_id+client_id+zone_id`. The
  creation page uses a zone select plus a client combobox (hotwire_combobox,
  fed by `client_options`) and a client panel reloaded by
  `client-panel-filter`.
- `daily_product_orders` has `client_id`, `zone_id`, `route_id`,
  `product_id`, `quantity`, `day`. The batch listing groups by
  `day+zone_id+route_id` and does not use `client_id`.
- `DailyProductOrderGeneration` sums per client+product defaults and pending
  products. `DailyProductOrderConsolidation` writes pending product columns.
- Zone → route selects already exist on the daily order index: the route
  select sits in a Turbo Frame reloaded by `client-zone-filter`.
- The local production environment (`bin/local-prod`) has its own database
  holding real clients, routes and products.

## Goals / Non-Goals

**Goals:**
- Reshape both tables in one migration that runs safely on development and on
  the local production database.
- Reuse the existing zone → route frame pattern and panel pattern instead of
  adding new JavaScript.

**Non-Goals:**
- Changing pending products (model, screens, states). They stay as a
  standalone tracking list.
- Managing defaults from the route form (the defaults page stays separate;
  only the sidebar moves it under "Rutas").
- Keeping or converting existing default quantities or daily orders.

## Decisions

### 1. One migration that deletes rows, rather than a database reset

The migration deletes all rows of `daily_product_orders` and
`default_product_quantities`, then:
- `default_product_quantities`: remove `client_id` and `zone_id` (with their
  foreign keys and indexes), add `route_id` (`null: false`, foreign key),
  add a unique index on `route_id+product_id`.
- `daily_product_orders`: remove `client_id` (foreign key and index).

The `down` direction re-adds the columns as nullable references (data cannot
be restored), so a rollback is possible in development.

*Alternative:* tell people to run `db:reset`. Rejected: it would also wipe
real clients, routes and products in the local production database. The
user said the current *default/daily* data is not important; dropping only
those rows keeps the rest. Development can still run `bin/rails db:reset`
to reseed.

### 2. `DefaultProductQuantity` belongs to route and product only

`belongs_to :route`, `belongs_to :product`;
`validates :quantity, numericality: { only_integer: true, greater_than: 0 }`;
`validates :product_id, uniqueness: { scope: :route_id }`. The zone is read
through `route.zone` (`delegate :zone, to: :route`). There is no stored
`zone_id`, so a default cannot disagree with its route's zone.

Associations:
- `Route has_many :default_product_quantities, dependent: :destroy`, declared
  **after** `has_many :daily_product_orders, dependent: :restrict_with_error`
  so a referenced route aborts before anything is destroyed (same rule as
  route stops).
- Remove `has_many :default_product_quantities` from `Client` and `Zone`.
- Remove `has_many :daily_product_orders` from `Client`.
- `Product` keeps both associations with `restrict_with_error`.

Filters: `filter_by_zone_id` joins `:route` and matches `routes.zone_id`;
`filter_by_route_id` matches `route_id`. The client-name filter is removed.

### 3. `DailyProductOrder` keeps `zone_id`, drops `client_id`

Keeping `zone_id` avoids touching the batch grouping, the zone filter and the
`Zone` delete protection. It is always set from `route.zone` by the
generator, so it cannot drift in practice.

*Alternative:* also drop `zone_id` and join through routes. Rejected for
this change: more query changes for no visible benefit.

### 4. Generation copies the route's defaults

```ruby
DefaultProductQuantity.where(route: @route).find_each do |default|
  DailyProductOrder.create!(zone: @zone, route: @route, product_id: default.product_id,
                            quantity: default.quantity, day: @day)
end
```

inside the existing transaction that first deletes the route+day batch.
Since defaults are always > 0 and unique per route+product, no summing or
zero-skipping is needed.

### 5. Consolidated spreadsheet drops pending columns

The client table becomes just `Cliente | Dirección | Ubicación` per route
stop (in stop order). The product totals table keeps its current shape
(grouped by product name over the batch, sorted by name). The helper methods
for pending products are removed.

### 6. Default quantity screens: route select instead of client combobox

- **Index**: columns Zona, Ruta, Producto, Cantidad, Acciones; order by
  `zones.name, routes.name, products.name`; filters `zone_id` and `route_id`
  using the same pattern as the daily order table filters (route select in a
  Turbo Frame reloaded by `client-zone-filter`, cleared via
  `data-auto-submit-clear-param="route_id"`, route ignored when it does not
  belong to the zone).
- **Creation form**: zone select → route select inside a Turbo Frame
  (`route_select`) reloaded by `client-zone-filter`; product select;
  quantity `min: 1`. The `client_options` endpoint and the combobox go away;
  no new route is needed because the frame reloads the `new` page itself
  with `zone_id`.
- **Route panel**: rename the client panel partials to route ones
  (`_route_panel`, `_route_default_list`) with `dom_id(route,
  :default_product_quantities)`. The `new` action reads `route_id`.
  `client-panel-filter` hardcodes `client_id` and listens to combobox
  events; give it a `param` value (default `"client_id"`, so pending products
  keep working) and make it read the value from a plain `change` event
  (`event.target.value`) as well as `event.detail.value`.
- **Edit modal**: shows zone and route as fixed values; permits only
  `product_id` and `quantity`.
- **Delete confirmation label**: "<route name> / <product name>".

### 7. Sidebar

`Rutas` becomes a hover group (same markup as today's Productos group) with
links "Rutas" and "Default" (`nav.products_default` renamed to
`nav.routes_default`). "Productos", "Pendientes" and "Orden Diaria" become
plain top-level links. Active state is computed from `controller_name`:
`routes` and `default_product_quantities` highlight the Rutas group;
`products`, `pending_products` and `daily_product_orders` highlight their
own link. A small helper (`nav_link_class(active)`) avoids repeating the
long class string.

### 8. Seeds

`db/seeds/development.rb`: routes are `find_or_create_by!` (never
recreated), so the defaults block stays where it is. It still runs
`DefaultProductQuantity.delete_all`, then gives each route 2–4 of the
sample products, picked at random, with `rand(5..30)`. Update the file's
header comment if needed. Production seeds are unchanged.

## Risks / Trade-offs

- [Running the migration on the local production database deletes its
  default quantities and daily orders] → Accepted by the user; called out in
  tasks so it is run knowingly (`bin/local-prod` migrate step).
- [Deleting a route now silently deletes its defaults] → Same as route stops
  today; the route deletion still requires confirmation.
- [`client-panel-filter` is shared with pending products] → The new `param`
  value defaults to `client_id`, and the pending product request specs cover
  the existing behavior.
- [Pending products no longer reach the driver's sheet] → Requested by the
  user; pending products remain visible on their own screen.

## Migration Plan

1. Deploy code and run `bin/rails db:migrate` (development), then
   `bin/rails db:seed` or `db:reset` to get route-based sample defaults.
2. Local production: run `bin/local-prod update`. It backs up the database
   before migrating. Existing defaults and daily orders are removed; defaults
   are then entered per route from the new screen.
3. Rollback: `db:rollback` restores the old columns (nullable, empty);
   revert the code.
