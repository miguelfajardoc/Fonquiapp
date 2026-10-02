## Why

Since `add-index-filters` moved the index tables into Turbo Frames, the
"Editar" links on the Productos and Default indexes no longer work. Clicking
one shows "Content missing" instead of opening the edit form. A link inside a
`<turbo-frame>` navigates only that frame by default: Turbo requests the edit
page as a frame request, the edit page has no matching frame, and Turbo
discards the response. This was reproduced in headless Chromium on
Productos, where Turbo reports "The response (200) did not contain the
expected `<turbo-frame id="products">`". Default uses the identical link.

Separately, the client index has never had an "Editar" button. The original
`client-management` spec only offered "Eliminar" per row, and editing was
reached through the row → detail page → "Editar". Staff expect the same
per-row edit control the other indexes have.

## What Changes

- Make the per-row "Editar" links on the Productos and Default indexes break
  out of the table frame (`data-turbo-frame="_top"`). They open the full edit
  page again, and saving or cancelling returns to the index as before.
- Add an "Editar" button to every client row, next to "Eliminar". It opens
  the client edit form with a full-page visit. Clicking it does not also
  trigger the row's open-detail behavior. Clicking elsewhere on the row still
  opens the detail view.
- Pendientes: the reported "Content missing" was **not reproducible** with
  the current code. In headless Chromium the edit modal opens, saving closes
  it and updates the row, and "Entregar" updates the row. No code change is
  planned. A regression check confirms it in the browser.
- Add request specs that pin the `_top` target on every in-frame edit link,
  and a scripted headless-browser check that clicks "Editar" on each index.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `product-management`: the product index's edit control opens the edit
  form even when the list is filtered or paginated.
- `default-product-quantity-management`: the same for the default index's
  edit control.
- `client-management`: the client index listing gains a per-row edit
  control.

## Impact

- **Views**: `products/index.html.erb`,
  `default_product_quantities/index.html.erb`, `clients/index.html.erb`, and
  `es.yml` (`clients.index.edit`).
- **Tests**: `spec/requests/products_spec.rb`,
  `spec/requests/default_product_quantities_spec.rb`,
  `spec/requests/clients_spec.rb`.
- **No** model, controller, route, JS, or schema changes.
