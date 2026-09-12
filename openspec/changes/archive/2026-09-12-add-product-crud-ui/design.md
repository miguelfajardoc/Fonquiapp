## Context

See `proposal.md` - Why/What Changes. `Product` (`app/models/product.rb`)
already validates `name` (presence, uniqueness) and `price` (presence,
numericality `>= 0`), and has three `has_many ... dependent:
:restrict_with_error` associations (`pending_products`,
`default_product_quantities`, `daily_product_orders`), so `product.destroy`
already returns `false` (with a base error) instead of raising, when the
product is still referenced — the exact same shape `Zone` already has. No
`ProductsController` or `app/views/products/*` exist yet. The app shell
(`add-app-shell-navigation`) already renders every page inside a sidebar +
header; its "Productos" submenu currently renders all four entries as
inert `<span>`s (`app/views/layouts/_sidebar.html.erb:17-20`), with the
"Productos" entry deliberately left inert only because no product view
existed yet (per that change's design.md: "the moment a first entry gets
a real view, this should be revisited"). No `rails-i18n` gem is installed,
so `number_to_currency` currently has no Spanish/Colombian number-format
translations and would fall back to English (`$`, `,` delimiter, `.`
separator, 2 decimals) if called without explicit options or added locale
data.

## Goals / Non-Goals

**Goals:**
- Ship a working CRUD flow for `Product` (all actions but `show`), styled
  and structured identically to the existing Zonas flow (same table
  layout, same shared confirm-dialog modal, same form/flash conventions).
- Display price as Colombian-peso currency with no decimal places on the
  index, without changing the model's two-decimal storage
  (`product-catalog` is unmodified).
- Connect the sidebar's "Productos" submenu entry to the new index now
  that the view exists, leaving the other three submenu entries and the
  top-level "Productos" entry exactly as `add-app-shell-navigation` left
  them.

**Non-Goals:**
- Any change to `Product`'s validations, associations, or stored precision
  — `product-catalog`'s two-decimal-place requirement is unchanged; only
  the product management flow's display layer rounds for presentation.
- Building controllers/views for `DefaultProductQuantity`,
  `PendingProduct`, or `DailyProductOrder`, or linking the submenu's
  "Default"/"Pendientes"/"Orden Diaria" entries. They remain inert.
- A generic currency-formatting helper reused across the app. This change
  only needs it for the product index, so it is scoped to what
  `number_to_currency` plus one new locale entry provides.

## Decisions

### Controller mirrors `ZonesController`, without the modal-embed pieces

`ProductsController` gets `index`, `new`, `create`, `edit`, `update`,
`destroy`, with `set_product`/`product_params` (`params.expect(product:
[:name, :price])`) analogous to `ZonesController`. `create`/`update`
re-render `new`/`edit` (422) with the invalid `@product` on validation
failure; `destroy` redirects with a success flash on `true`, or an alert
built from `@product.errors.full_messages` on `false`. Zone's
`NEW_ZONE_MODAL_FRAME`/turbo-stream machinery (for creating a zone inline
from the client form) has no product equivalent in this proposal — nothing
today embeds product creation inside another form — so it is not carried
over.

### Price input: a plain number field, whole pesos

The form's price field is `form.number_field :price, min: 0, step: 1` —
matching the user's direction that Colombian pesos are never entered with
decimals. This is a UI affordance only (the model still accepts and stores
two decimal places per `product-catalog`, unchanged); it does not add or
change any server-side validation, so a value that somehow arrives with
cents is still accepted exactly as it is today.

### Price display: `number_to_currency` with a new locale entry, no gem

Rather than pass formatting options at every call site, a
`number.currency.format` entry is added under `es:` in
`config/locales/es.yml` (unit `"$"`, delimiter `"."`, separator `","`,
precision `0`), so plain `number_to_currency(product.price)` on the index
renders e.g. `$12.000` given the app's default locale is already `:es`
(`config/application.rb`). Alternative considered: add the `rails-i18n`
gem for full Spanish number/date formats. Rejected as unnecessary for one
field; the app has no other numeric/date formatting need today, and adding
a dependency for a single locale key is disproportionate.

### View structure

- `products/index.html.erb`: "Crear producto" button above a 3-column
  table (Nombre / Precio / Acciones); one row per product with Editar
  (link to `edit`) and Eliminar (opens the confirmation modal) — same
  structure as `zones/index.html.erb`.
- `products/_form.html.erb`: shared partial for `new`/`edit` — Nombre
  (text) and Precio (number, as above) fields, a submit button labeled
  "Crear" on `new`/"Actualizar" on `edit`, and a "Cancelar" link to
  `products_path` — mirrors `zones/_form.html.erb`'s structure and error
  summary block.
- `products/new.html.erb`/`edit.html.erb`: thin wrappers rendering the
  shared form with a heading, same as Zonas.
- The existing `shared/_confirm_dialog` partial and `modal_controller.js`
  are reused as-is (already generic over "name" + delete URL via data
  attributes); no new JavaScript.

### Sidebar: only the "Productos" submenu entry changes

In `_sidebar.html.erb`, the first submenu `<span>`
(`t("nav.products")`) becomes `link_to t("nav.products"), products_path`,
styled to match the other three muted entries when not hovered/focused
(no distinct active-state styling is introduced here, since the
`app-shell` spec's active-highlighting requirement only covers the
top-level Zonas/Clientes entries, unchanged by this proposal). The
top-level "Productos" entry stays a non-link `<div>` exactly as before —
its role is still only to reveal the submenu on hover, per
`add-app-shell-navigation`'s unmodified "Top-level navigation entries"
requirement.

## Risks / Trade-offs

- **Rounding a two-decimal price to zero decimals for display** could
  visually hide a non-integer price (e.g. `12000.50` displays as
  `$12.001` after rounding) if one is ever entered outside the UI's
  whole-peso number field (e.g. via the console or a future API). Accepted
  per the user's explicit direction that Colombian pesos are never
  fractional in this app's domain; `product-catalog`'s stored precision is
  untouched, so no data is lost, only the index's display rounds.
- **The locale-level currency format is global**, not scoped to products.
  Low risk: no other feature currently calls `number_to_currency`, so
  there is nothing else to affect; a future feature needing different
  currency formatting can override it per-call.

## Migration Plan

Purely additive/structural, plus one small edit to an existing partial:
new route, new controller, new views/partial, one new locale namespace
(`products`) and one new locale key (`number.currency.format`), and the
one-line sidebar link change. No data migration, no changes to `Product`
or its migrations. Rollback is deleting the added files/route, reverting
the locale file and the sidebar partial's submenu-link line.
