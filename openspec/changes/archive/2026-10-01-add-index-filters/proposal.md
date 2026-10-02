## Why

The client index now has filters, pagination, and a cleaner layout (see the
archived `add-client-index-filters` change). The other list screens still
show every record unfiltered, repeat the page title under the header, and
put the create button on its own row. Products, defaults, pending products,
and daily order batches keep growing, so staff need the same way to narrow
them down. The daily order table also lists a freshly generated batch below
older batches of the same day, which hides the result of the action just
taken.

## What Changes

- **Productos**: a name filter (contains, ignoring case and accents, same as
  clients), pagination, and a "Limpiar filtros" button.
- **Default** (default product quantities): filters by client name (contains,
  ignoring case and accents) and by zone. A new "Zona" column, pagination,
  and "Limpiar filtros".
- **Pendientes** (pending products): filters by zone, client name, and state
  (Pendiente / Entregado / Cancelado), plus a sort select for creation date
  ("Más recientes primero", the default, or "Más antiguos primero"). A new
  "Zona" column, pagination, and "Limpiar filtros".
- **Orden Diaria**: a second, visually separate filter bar below the
  generation form, with a zone filter and a route filter that depends on the
  zone. It filters the batch table only. Add "Limpiar filtros".
  **BREAKING (ordering)**: batches are listed by most recent generation
  first, not by day and then zone/route name. A batch that was just
  generated or regenerated appears at the top.
- **All index pages** (Clientes, Productos, Default, Pendientes, Orden
  Diaria, Zonas, Rutas): remove the in-page `<h1>` title (the header already
  shows it), add some spacing between the header and the first row, and put
  the create button on the filters' row, aligned right. Create, edit, and
  detail pages keep their titles for now.
- Filters behave as on the client index: they apply automatically, only the
  table refreshes, they live in the URL (not the session), and changing a
  filter returns to page 1.
- Reuse the existing building blocks (`Filterable`, `auto-submit`, the shared
  pagination partial) and generalize them where needed. The zone-dependent
  frame controller takes a configurable param name, and the accent- and
  case-insensitive "contains" match becomes a shared helper.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `product-management`: the product index listing gains a name filter and
  pagination.
- `default-product-quantity-management`: the index listing gains a zone
  column, client-name and zone filters, and pagination.
- `pending-product-management`: the index listing gains a zone column, zone,
  client-name, and state filters, a creation-date sort, and pagination.
- `daily-product-order-management`: the batch listing is ordered by most
  recent generation and gains zone and route table filters, separate from
  the generation form.

## Impact

- **Models**: `Filterable` (shared accent-insensitive contains helper);
  `Client.filter_by_name` refactored onto it; new `filter_by_*` scopes on
  `Product`, `DefaultProductQuantity`, `PendingProduct`, and
  `DailyProductOrder`.
- **Controllers**: `index` in `ProductsController`,
  `DefaultProductQuantitiesController`, `PendingProductsController`, and
  `DailyProductOrdersController` (filters, sort, Pagy, batch ordering).
- **JavaScript**: `client_zone_filter_controller.js` gets an optional `param`
  value (default `zone_id`). There is no new controller.
- **Views**: the index pages of products, default product quantities,
  pending products (plus the `_row` partial for the zone column), daily
  product orders, clients (spacing), zones, and routes. Plus `es.yml`.
- **Tests**: model specs for the new scopes, and request specs for the four
  filtered indexes and the daily batch ordering.
- **Dependencies/DB**: none. `unaccent` and Pagy are already in place.
