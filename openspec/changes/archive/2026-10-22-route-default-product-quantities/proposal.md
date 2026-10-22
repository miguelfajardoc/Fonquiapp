## Why

Standing default quantities are set per client today, but the business plans
deliveries per route: each route carries a fixed load of each product. Keeping
defaults per client, and adding pending products into the daily totals, makes
the daily order harder to set up and does not match how trucks are loaded.
The sidebar also groups unrelated sections under "Productos".

## What Changes

- **BREAKING** `DefaultProductQuantity` belongs to a route and a product
  (no longer to a client or a zone). Each route has at most one default per
  product, and the quantity must be greater than zero (a route only lists the
  products it needs). Existing default quantities and daily orders are
  discarded by the migration; the current data is not important.
- Default quantity screens (index, creation page, edit modal, deletion) work
  by zone → route instead of zone → client: the index shows zone, route,
  product and quantity, filtered by zone and route; the creation page lists
  the chosen route's defaults below the form.
- Deleting a route also deletes its default quantities (they are part of the
  route's setup); a route referenced by daily orders still cannot be deleted.
- **BREAKING** `DailyProductOrder` no longer references a client: one record
  per route+product per day.
- Daily order generation no longer uses pending products: it creates one
  daily order per product with a default for the chosen route, with that
  default's quantity.
- The consolidated spreadsheet no longer shows pending products: the client
  table keeps name, address and location per route stop, and the product
  totals come from the batch.
- Sidebar: "Rutas" becomes a hover group with "Rutas" and "Default";
  "Productos", "Pendientes" and "Orden Diaria" become separate top-level
  links; "Productos" no longer has a submenu.
- Development seeds create route-based defaults.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `product-ordering`: the default product quantity record references a route
  and a product (unique per route+product, quantity > 0); the daily product
  order record no longer references a client; delete-protection rules follow
  the new references.
- `default-product-quantity-management`: listing, filters, creation, editing
  and the creation-page list are scoped by zone → route instead of
  zone → client.
- `daily-product-order-management`: generation uses only the route's
  defaults; the consolidated spreadsheet drops the pending product columns.
- `route-planning`: deleting a route also deletes its default quantities.
- `app-shell`: new sidebar structure (Rutas submenu; Productos, Pendientes
  and Orden Diaria as top-level links) and active highlighting for every
  top-level entry.

## Impact

- **Database**: migration on `default_product_quantities` (drop `client_id`
  and `zone_id`, add `route_id`, unique index on `route_id+product_id`) and
  on `daily_product_orders` (drop `client_id`); existing rows of both tables
  are deleted.
- **Models**: `DefaultProductQuantity`, `DailyProductOrder`, `Route`,
  `Client`, `Zone`, `Product`.
- **Controllers / views**: `DefaultProductQuantitiesController` and its
  views, `layouts/_sidebar`, `config/routes.rb` (`client_options` →
  `route_options` for defaults), `config/locales/es.yml`.
- **Services**: `DailyProductOrderGeneration`,
  `DailyProductOrderConsolidation`.
- **Seeds**: `db/seeds/development.rb`.
- **Tests**: model, request and service specs and factories for defaults,
  daily orders, routes and the app shell.
- Pending products are not changed; they simply stop feeding daily orders
  and the spreadsheet.
