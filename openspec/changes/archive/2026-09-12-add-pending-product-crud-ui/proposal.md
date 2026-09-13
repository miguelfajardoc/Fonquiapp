## Why

`PendingProduct` records (per-client pending deliveries) already exist as a
data model (see the `product-ordering` spec), but staff have no web interface
to list, create, edit, mark delivered, or delete them. They currently need console
or database access to manage pending deliveries.

## What Changes

- Add routes and a controller for `PendingProduct` covering index, new,
  create, edit, update, and destroy (no `show` route).
- Add an index page listing every pending product (creation date, client,
  product, quantity, state) with per-row edit, delete, and a state toggle
  (Pendiente ⇄ Entregado), and a "Crear Pendiente" button.
- Add a create page with a small form (client combobox, product dropdown,
  quantity) above a live, client-scoped list of that client's pending
  products, updated via Turbo without a full page reload when the chosen
  client changes, when a pending product is created, or when one is edited
  or its state is toggled.
- Add a shared edit modal (used from both the index page and the create
  page's live list) that submits via Turbo and updates the underlying list
  in place without navigating away or reloading the page.
- Connect the sidebar's existing "Pendientes" submenu entry to the new
  index page, matching the pattern already used for "Productos" and
  "Default".
- Visually distinguish the "Pendiente" and "Entregado" (`delivered`) states
  with distinct colors; "Cancelado" is displayed without a highlight color
  (and is not reachable from this UI yet — the toggle only switches between
  Pendiente and Entregado).

## Capabilities

### New Capabilities

- `pending-product-management`: web routes, index listing, the create page
  with its live client-scoped pending list, the shared edit modal, state
  toggling between Pendiente and Entregado, and deletion with confirmation
  for pending products.

### Modified Capabilities

- `app-shell`: the "Pendientes" submenu entry becomes a link to the pending
  product index, matching how "Productos" and "Default" already link to
  their own indexes.

## Impact

- New `config/routes.rb` entries for `pending_products` (plus a
  collection route to back the client combobox's async search, mirroring
  `default_product_quantities`).
- New `PendingProductsController`, views under `app/views/pending_products/`,
  and a new Stimulus controller for the live client-scoped list / edit
  modal interaction.
- `app/views/layouts/_sidebar.html.erb`: "Pendientes" becomes a real link.
- `config/locales/es.yml`: new `pending_products` namespace.
- `app/assets/tailwind/application.css`: new color tokens for the
  Pendiente/Entregado state badges.
- No changes to the `PendingProduct` model or its existing validations —
  this change only adds the UI/controller layer on top of the model
  covered by `product-ordering`.
