## Why

`DailyProductOrder` records already exist as a data model (see `product-ordering`),
but nothing computes or persists them yet: staff have no way to generate a
zone's daily delivery totals from standing defaults plus pending deliveries,
or to hand a driver/warehouse team a consolidated pick sheet for a day's run.

## What Changes

- Add a `daily_product_orders` index page: a zone filter with a "Generar"
  button, and below it a list of already-generated batches grouped by
  (día, zona), each row's "Acción" offering a "Descargar consolidado" button.
- Add a `DailyProductOrderGeneration` service (`app/services/`) that, for a
  chosen zone, computes each client+product total as that combination's
  `DefaultProductQuantity` quantity (0 if none) plus the sum of that
  client+product's `PendingProduct` records still in `pending` state, skips
  zero totals, and persists the non-zero ones as `DailyProductOrder` rows
  dated with the generation date. Regenerating the same zone on the same day
  replaces (deletes then recreates) that day+zone's existing rows rather than
  accumulating duplicates.
- Add a `DailyProductOrderConsolidation` service (`app/services/`) that
  builds a downloadable XLSX workbook for one generated (día, zona) batch:
  a per-client table (Cliente, Dirección, Ubicación as a clickable link,
  and that client's currently-pending products as `<producto>: <cantidad>`
  each in its own column) for the batch's clients, followed by a
  Producto/Cantidad table summing that batch's `DailyProductOrder` quantities
  per product.
- Connect the sidebar's existing "Orden Diaria" submenu entry to the new
  index page, matching the pattern already used for "Productos", "Default",
  and "Pendientes".
- Add the `caxlsx` gem for XLSX generation (no existing spreadsheet/export
  dependency in the app).

## Capabilities

### New Capabilities

- `daily-product-order-management`: the generation index page, the zone-scoped
  generation service (with same-day replace-on-regenerate semantics), the
  grouped (día, zona) listing, and the per-batch consolidated XLSX download.

### Modified Capabilities

- `app-shell`: the "Orden Diaria" submenu entry becomes a link to the daily
  product order index, matching how "Productos", "Default", and "Pendientes"
  already link to their own indexes.

## Impact

- New `config/routes.rb` entries: `daily_product_orders` index plus
  collection actions for generating and downloading the consolidation.
- New `DailyProductOrdersController`, views under
  `app/views/daily_product_orders/`.
- New `app/services/daily_product_order_generation.rb` and
  `app/services/daily_product_order_consolidation.rb`.
- `app/views/layouts/_sidebar.html.erb`: "Orden Diaria" becomes a real link.
- `config/locales/es.yml`: new `daily_product_orders` namespace.
- `Gemfile`: add `caxlsx`.
- No changes to the `DailyProductOrder`, `PendingProduct`, or
  `DefaultProductQuantity` models or their existing validations — this
  change only adds a generation/reporting layer on top of the data already
  covered by `product-ordering`.
