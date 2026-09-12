## Why

`DefaultProductQuantity` (product + client + zone + quantity, one-per-combination)
already exists as a validated model (`app/models/default_product_quantity.rb`),
but nothing in `app/controllers`/`app/views` exposes it — staff can only manage
standing default quantities through the Rails console or seeds. This adds the
web CRUD flow, following the same pattern already established for Zonas,
Clientes, and Productos, and connects the sidebar's "Default" submenu entry
(added inert in `add-app-shell-navigation`, pending this exact flow) to the
new index.

## What Changes

- Add `resources :default_product_quantities, except: [:show]` routes plus a
  collection route for the client-search endpoint the form's combobox uses,
  and a `DefaultProductQuantitiesController` with `index`, `new`, `create`,
  `edit`, `update`, `destroy` — no `show` action/view, matching the existing
  flows.
- Add a `default_product_quantities/index` view: a table with Cliente,
  Producto, Cantidad, and Acciones columns (Editar/Eliminar per row), and a
  "Crear default" button above the table (top-right, matching Zonas/
  Clientes/Productos).
- Add a shared `default_product_quantities/_form` partial (used by `new` and
  `edit`) with: a Zona select (plain dropdown, all zones), a Cliente combobox
  (searchable, scoped to the selected zone, built with the `hotwire_combobox`
  gem — new dependency), a Producto select (plain dropdown, all products),
  and a Cantidad number field (integer, minimum 0) — a submit button labeled
  "Crear" on `new`/"Actualizar" on `edit`, and a "Cancelar" link back to the
  index.
- Changing the Zona select reloads the Cliente combobox (via a Turbo Frame)
  to only offer that zone's clients, and clears any previously selected
  client.
- Add a delete-confirmation modal (reusing the existing
  `shared/_confirm_dialog` partial and `modal` Stimulus controller) shown
  when Eliminar is pressed on the index.
- Surface a flash/form error when a submission would violate the model's
  existing one-default-per-product+client+zone uniqueness rule, instead of
  an unhandled error.
- Connect the sidebar: the "Default" entry inside the Productos submenu
  (`app/views/layouts/_sidebar.html.erb`) becomes a link to the new index.
  "Pendientes" and "Orden Diaria" remain inert, since `PendingProduct` and
  `DailyProductOrder` still have no controller or views.
- Add the `hotwire_combobox` gem (by José Farías) and its minimal asset
  setup (stylesheet tag in the layout; no importmap changes expected per
  its own install docs, to be confirmed while implementing).

## Capabilities

### New Capabilities
- `default-product-quantity-management`: the web CRUD flow for default
  product quantities — routes, controller behavior (including the show
  exclusion, the zone-scoped client search endpoint, and the
  uniqueness-violation error), and the index/create/edit/delete-modal views.
  Named to parallel `zone-management`/`product-management`, distinct from
  `product-ordering` (the model's own persistence rules, unchanged here).

### Modified Capabilities
- `app-shell`: the "Default" submenu entry's requirement changes from "not
  a link" to "links to the default-product-quantity index," now that its
  index exists. The top-level "Productos" entry and the other two submenu
  entries (Pendientes, Orden Diaria) are unchanged.

## Impact

- **Routes**: `config/routes.rb` gains `resources :default_product_quantities,
  except: [:show]` plus a collection route for the client-search endpoint.
- **Controllers**: new `app/controllers/default_product_quantities_controller.rb`.
- **Views**: new `app/views/default_product_quantities/index.html.erb`,
  `new.html.erb`, `edit.html.erb`, `_form.html.erb`;
  `app/views/layouts/_sidebar.html.erb` changes the "Default" submenu entry
  from a `<span>` to a link; `app/views/layouts/application.html.erb` gains
  `combobox_style_tag` in the head.
- **i18n**: `config/locales/es.yml` gains a `default_product_quantities`
  namespace (mirroring `zones`/`products`).
- **JavaScript**: a small new Stimulus controller to reload the client
  combobox's Turbo Frame when the zone changes; reuses the existing
  `modal_controller.js` for delete confirmation.
- **Dependencies**: new gem, `hotwire_combobox`.
