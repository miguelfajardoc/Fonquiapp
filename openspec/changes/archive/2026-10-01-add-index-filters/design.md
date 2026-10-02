## Context

See proposal.md (Why). The client index (`add-client-index-filters`) set the
pattern this change copies:

- A GET filter form **outside** a `<turbo-frame>` that wraps the table,
  empty-state row, and `shared/pagination`. The frame has
  `data-turbo-action="advance"`, so filters and page links update the URL.
- `auto-submit` Stimulus controller: `debouncedSubmit` for text, and `submit`
  with an optional `clear` param for selects.
- `client-zone-filter` Stimulus controller: reloads a target frame from the
  current URL with **`zone_id`** swapped in. Both the client filters and the
  daily-order **generation** form use it.
- `Filterable` concern: `filter_by(params)` calls `filter_by_<key>` for each
  non-blank permitted key. `Client.filter_by_name` inlines
  `unaccent(...) ILIKE unaccent(?)` with `sanitize_sql_like`.
- A "Limpiar filtros" link to the bare index path with
  `data-turbo-frame="_top"`, which does a full visit that empties every
  control.

Current state of the target screens:

- `ProductsController#index`: `Product.order(:name)` (6 rows).
- `DefaultProductQuantitiesController#index`:
  `includes(:client, :product).order("clients.name", "products.name")`. The
  table has no zone column, but `default_product_quantities.zone_id` exists.
- `PendingProductsController#index`:
  `includes(:client, :product).order(created_at: :desc)`. Rows render through
  `pending_products/_row`, which `toggle_state` and the edit modal also
  replace by `dom_id` via Turbo Stream. `pending_products.zone_id` exists.
  States: `pending` 0, `delivered` 1, `canceled` 9.
- `DailyProductOrdersController#index`: the generation form keeps its zone
  in `?zone_id=` (it drives the `route_select` frame), and batches are a
  grouped relation ordered `day DESC, zones.name, routes.name`, paginated by
  Pagy.
- Every index page renders an `<h1>` that repeats the header title. `main`
  already has `py-8 gap-4`.

## Goals / Non-Goals

**Goals:**
- The same look and behavior on every filtered index, with no per-view
  JavaScript.
- The daily table filters and the generation form never interfere with each
  other.

**Non-Goals:**
- Keep the titles on new, edit, and show pages.
- No filters on Zonas or Rutas (title and layout cleanup only).
- No sorting other than the pending-products creation-date select.
- No session persistence.

## Decisions

### 1. Shared accent-insensitive "contains" helper in `Filterable`

Add a class method to the concern:

```ruby
def where_unaccent_contains(column_sql, text)
  where("unaccent(#{column_sql}) ILIKE unaccent(?)", "%#{sanitize_sql_like(text)}%")
end
```

`column_sql` is always a literal written in the model (never user input).
Usage:
- `Client.filter_by_name` → `where_unaccent_contains("clients.name", v)`
  (refactor, same behavior)
- `Product.filter_by_name` → `"products.name"`
- `DefaultProductQuantity.filter_by_client_name` and
  `PendingProduct.filter_by_client_name` →
  `joins(:client).where_unaccent_contains("clients.name", v)`

*Alternative*: copy the SQL into each scope. That would mean four copies of
the escaping logic.

### 2. Scopes per model

- `Product`: `filter_by_name`.
- `DefaultProductQuantity`: `filter_by_client_name`, `filter_by_zone_id`.
- `PendingProduct`: `filter_by_client_name`, `filter_by_zone_id`, and
  `filter_by_state`. `filter_by_state` uses `where(state: v)` only when `v`
  is one of `states.keys`. Otherwise it is a no-op, so a bad URL value never
  raises an error.
- `DailyProductOrder`: `filter_by_zone_id`, `filter_by_route_id`.

Each controller keeps a `FILTER_KEYS` constant and
`params.slice(*FILTER_KEYS).permit(*FILTER_KEYS)`, as `ClientsController`
does.

### 3. Pending sort is a whitelisted param, not a filter

`params[:sort]`: `"oldest"` gives `order(created_at: :asc)`. Anything else,
including blank, gives `order(created_at: :desc)`. Add `id` as a tiebreaker
in the same direction, so pages are stable when timestamps are equal. The
sort select sits in the filter form with `change->auto-submit#submit`.
"Limpiar filtros" drops it, which returns to the default.

### 4. Zone column for Default and Pendientes

Show `record.zone.name` after the client column. Preload `:zone` in both
indexes. Because `pending_products/_row` is shared with `toggle_state` and
the edit modal, the column is added to the partial itself, so streamed row
replacements keep the same shape. Add the header `<th>` and bump the
empty-state `colspan`.

### 5. Daily order: separate table filters with their own param names

- Table filter params are `filter_zone_id` and `filter_route_id`. The
  generation form keeps `zone_id` and `route_id`. Two forms on the page use
  the same URL, so distinct names keep them independent, and each one's
  frame reload carries the other's state untouched.
- `client-zone-filter` gets an optional `param` value
  (`static values = { param: { type: String, default: "zone_id" } }`) and
  sets that query key. The generation form keeps the default. The table
  filter form uses `data-client-zone-filter-param-value="filter_zone_id"`.
  The route select for the table filters lives in
  `turbo_frame_tag "batch_route_filter"`.
- Layout: the generation form stays at the top. Below it is a bordered
  section with a small heading "Filtrar tabla" that holds the table filter
  form and its "Limpiar filtros" link. The batch table, the empty state, and
  the pagination nav move into `turbo_frame_tag "daily_product_orders"`
  (advance). "Limpiar filtros" links to `daily_product_orders_path`.
- Controller: map to scopes with
  `{ zone_id: params[:filter_zone_id], route_id: params[:filter_route_id] }`.
  Drop `route_id` unless it belongs to the filter zone's routes, as on the
  client index. Load `@filter_routes` for the table zone, separately from
  the generation `@routes`.

### 6. Daily batch ordering by last generation time

Order the grouped relation by `MAX(daily_product_orders.created_at) DESC`.
Add the grouped key columns (`route_id`, `day`) as tiebreakers so
pagination is stable. Generation deletes and recreates a route+day batch,
so a regenerated batch's max `created_at` is the regeneration time, and it
moves to the top. Generation always uses `Date.current`, so "newest
generation first" also keeps days in descending order in practice.

*Alternative*: keep `day DESC` and order by generation time within the day.
The user chose pure generation order.

### 7. Index page chrome

On every index (Clientes, Productos, Default, Pendientes, Orden Diaria,
Zonas, Rutas):
- Remove the `<h1>`. Keep `content_for :title`, which feeds the header and
  the tab title.
- Top row: `<div class="mt-4 flex flex-wrap items-end justify-between gap-3">`
  with the filter form on the left and the create button on the right
  (`justify-end` when there are no filters: Zonas, Rutas). `mt-4` adds the
  breathing room the user asked for on top of `main`'s padding. Apply the
  same spacing to Clientes.
- Orden Diaria has no create button. Its top row is the generation form,
  and `mt-4` is applied there.

### 8. Pagination

`pagy(:offset, scope)` with the global limit of 20, in Productos, Default,
and Pendientes. Render `shared/pagination` inside each table frame. Filter
submits omit `page`, so they reset to page 1.

## Risks / Trade-offs

- [Combining `joins(:client)` (client-name filter) with
  `includes(:client)` and an order by `clients.name` can switch Active Record
  to `eager_load`, and interacts with Pagy's limit.] → The associations are
  all `belongs_to`, so there is no row multiplication and limit/offset stay
  correct. Request specs cover pagination combined with the name filter.
- [The default pending sort changes from `created_at` only to
  `created_at, id`.] → This is user-invisible and only fixes the order when
  timestamps are equal.
- [`MAX(created_at)` orders by generation time, not by `day`.] → Generation
  always stamps today, so the two agree. Older batches stay below.
- [The JS behavior (debounce, focus, dependent selects, independent forms
  on Orden Diaria) is not covered by request specs.] → A manual browser
  verification task covers it.

## Migration Plan

No schema or data changes. Deploy the code. Rollback is a code revert.
