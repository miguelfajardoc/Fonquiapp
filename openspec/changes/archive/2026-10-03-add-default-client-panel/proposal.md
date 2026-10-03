## Why

Pendientes already gives staff a fast entry flow:
- The "new" page shows the chosen client's existing pending products right
  below the form.
- Adding one keeps you on the page, so several can be entered in a row.
- Editing happens in a modal without leaving the list.

The Default (default product quantity) screens still work the old way. You
create a record blind, without seeing what that client already has, you
are sent back to the index after every save, and editing opens a separate
page. Setting up a client's standing order means entering several products
for the same client, which is exactly where the Pendientes flow pays off.

## What Changes

- **Default "new" page: client panel.** Below the form, show the chosen
  client's existing default product quantities (product, quantity, and
  Editar/Eliminar actions) under a heading naming the client. Until a client
  is chosen, show a prompt to choose one. The panel refreshes whenever the
  client choice changes, and clears when the zone changes, because the
  client is cleared too.
- **Zone → client selection is kept** (user decision). The form keeps the
  zone select and the client combobox limited to that zone.
- **Stay on the page after creating** (**BREAKING** vs. today's redirect to
  the index). A valid submit adds the record to the panel and resets the
  form for the next entry, keeping the same zone and client and clearing
  product and quantity. An invalid submit (including a duplicate
  client+product) re-renders the form with errors in place.
- **Edit in a modal** on both the Default index and the new-page panel,
  replacing the separate edit page. The modal shows the record's zone and
  client as fixed (read-only) and lets the user change **product and
  quantity only** (user decision). Saving closes the modal and updates that
  row in place. Errors keep the modal open with messages. Cancel closes it
  without changes.
- **Delete in place**: confirming a delete from the index or the panel
  removes that row without a full page reload.
- **Reuse instead of copying**: generalize the two Pendientes-only Stimulus
  controllers into shared ones, used by both screens:
  - `pending-product-edit-modal` becomes `edit-modal`.
  - `pending-product-client-filter` becomes `client-panel-filter`, which
    also clears the panel on a zone change.
  - The Pendientes edit-modal partial becomes a shared `shared/_edit_modal`.
  Pendientes behavior does not change.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `default-product-quantity-management`:
  - Creation keeps the user on the page.
  - Editing moves to a modal limited to product and quantity.
  - Deletion removes the row in place.
  - The index edit control opens the modal.
  - Adds a client-scoped list on the new page.

## Impact

- **Controller**: `DefaultProductQuantitiesController`:
  - `new` loads the client panel.
  - `create` and `update` respond with Turbo Streams.
  - `edit` renders the modal frame without a layout.
  - `update` permits only `product_id` and `quantity`.
  - `destroy` responds with a Turbo Stream when requested.
- **Views**: `default_product_quantities/new`, `_form`, `edit` (now a modal
  frame), the new `_client_panel`, `_client_default_list`, `_panel_item`,
  `_row`, and `_actions` partials, and `index` (rows via `_row`, the Editar
  button opens the modal, the shared modal is rendered).
- **Shared/JS**: rename and generalize `pending_product_edit_modal_controller.js`
  to `edit_modal_controller.js`, and `pending_product_client_filter_controller.js`
  to `client_panel_filter_controller.js`. Replace
  `shared/_pending_product_edit_modal` with `shared/_edit_modal`, and update
  the Pendientes views that use them.
- **Locales**: new `es.yml` strings for the panel and modal.
- **Tests**: Default request specs (new, create, update, destroy, index) and
  Pendientes request specs for the renamed controllers. Headless-browser
  verification of both screens.
- **No** model, route, or schema changes.
