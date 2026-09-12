## Why

`Product` (name, price) already exists as a validated model
(`app/models/product.rb`), but nothing in `app/controllers`/`app/views`
exposes it — staff can only manage the product catalog through the Rails
console or seeds. This adds the web CRUD flow, following the same pattern
already established for Zonas, and connects the sidebar's "Productos"
submenu entry (added inert in `add-app-shell-navigation`, pending this
exact flow) to the new index.

## What Changes

- Add `resources :products, except: [:show]` routes and a
  `ProductsController` with `index`, `new`, `create`, `edit`, `update`, and
  `destroy` actions — no `show` action/view, matching the Zonas flow.
- Add a `products/index` view: a table with Nombre, Precio, and Acciones
  columns (Editar/Eliminar per row), and a "Crear producto" button above
  the table. Price is displayed formatted as Colombian peso currency with
  no decimal places (e.g. "$12.000"), rounding the stored two-decimal value
  for display only — the underlying value and its two-decimal storage
  (`product-catalog`) are unchanged.
- Add a shared `products/_form` partial (used by `new` and `edit`) with two
  fields — Nombre (text) and Precio (number, whole pesos: no decimal step,
  minimum 0) — a submit button labeled "Crear" on `new` and "Actualizar" on
  `edit`, and a "Cancelar" link back to the index.
- Add a delete-confirmation modal (reusing the existing
  `shared/_confirm_dialog` partial and `modal` Stimulus controller from the
  Zonas flow) shown when Eliminar is pressed on the index.
- Surface a flash error on the index when deleting a product is blocked
  because pending products, default quantities, or daily orders still
  reference it (the model already enforces this via
  `restrict_with_error`), instead of a generic/unhandled error page.
- Connect the sidebar: the "Productos" entry inside the Productos submenu
  (`app/views/layouts/_sidebar.html.erb`) becomes a link to `products_path`.
  "Default", "Pendientes", and "Orden Diaria" remain inert, since their
  models still have no controller or views.

## Capabilities

### New Capabilities
- `product-management`: the web CRUD flow for products — routes,
  controller behavior (including the show exclusion and the
  delete-restriction flash), and the index/create/edit/delete-modal views.
  Named to parallel the existing `zone-management` web-flow capability,
  distinct from `product-catalog` (the `Product` model's own persistence
  rules, unchanged here).

### Modified Capabilities
- `app-shell`: the "Productos" submenu entry's requirement changes from
  "not a link" to "links to the product index," now that the product index
  exists. The top-level "Productos" entry and the other three submenu
  entries (Default, Pendientes, Orden Diaria) are unchanged.

## Impact

- **Routes**: `config/routes.rb` gains `resources :products, except:
  [:show]`.
- **Controllers**: new `app/controllers/products_controller.rb`.
- **Views**: new `app/views/products/index.html.erb`, `new.html.erb`,
  `edit.html.erb`, `_form.html.erb`; `app/views/layouts/_sidebar.html.erb`
  changes the "Productos" submenu entry from a `<span>` to a link.
- **i18n**: `config/locales/es.yml` gains a `products` namespace (mirroring
  `zones`) and a currency number-format entry so `number_to_currency`
  renders Colombian-peso formatting without a locale gem.
- **JavaScript**: none new — reuses the existing `modal_controller.js`.
- **Dependencies**: none new.
