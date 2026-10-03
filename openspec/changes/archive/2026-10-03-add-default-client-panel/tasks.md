## 1. Generalize the Pendientes building blocks

- [x] 1.1 Rename `pending_product_edit_modal_controller.js` to `edit_modal_controller.js` and `pending_product_client_filter_controller.js` to `client_panel_filter_controller.js`. Make `reload` handle a missing `event.detail` by removing `client_id`. Replace `shared/_pending_product_edit_modal.html.erb` with `shared/_edit_modal.html.erb`, which takes a `frame_id` local.
- [x] 1.2 Update every Pendientes reference (`index`, `new`, `edit`, `_actions`) to `edit-modal` and `client-panel-filter`, and render `shared/edit_modal` with `frame_id: "pending_product_edit_modal"`. Verify `grep` finds no old controller names, and that `bundle exec rspec spec/requests/pending_products_spec.rb` passes.

## 2. Default controller

- [x] 2.1 `new`: load `@selected_client` and `@client_defaults` (ordered by product name) from `params[:client_id]`.
- [x] 2.2 `create`: on success, Turbo Stream that replaces the client's default list and resets the form, keeping zone and client. On failure, replace the form with errors (422).
- [x] 2.3 `edit`: `render layout: false`. `update`: permit only `product_id` and `quantity`. On success, Turbo Stream that replaces `dom_id(record)` with `_panel_item` (`context=panel`) or `_row`. On failure, re-render `edit` (422).
- [x] 2.4 `destroy`: `respond_to` with `turbo_stream.remove(dom_id(record))`, keeping the HTML redirect fallback.

## 3. Default views and locales

- [x] 3.1 Create the partials `_row` (index table row with `dom_id`), `_actions` (an Editar button that opens `edit-modal` with `context`, plus the delete button), `_panel_item`, `_client_default_list` (`id = dom_id(client, :default_product_quantities)`, column headers, empty message), and `_client_panel` (heading or choose-a-client prompt).
- [x] 3.2 `_form`: add `id: "default_product_quantity_form"` and the `create` URL. Make the zone select also trigger `client-panel-filter#reload`. `new.html.erb`: add the panel layout from design.md decision 2, the confirm dialog, and `shared/edit_modal`.
- [x] 3.3 `edit.html.erb`: modal frame `default_product_quantity_edit_modal` with read-only zone and client, the product select and quantity field, and Cancel (`edit-modal#close`) / Actualizar.
- [x] 3.4 `index.html.erb`: render rows through `_row`, put `data-controller="modal edit-modal"` on the root, and render `shared/edit_modal`. Add the `es.yml` strings for the panel and modal.

## 4. Specs

- [x] 4.1 Update `spec/requests/default_product_quantities_spec.rb`:
  - The panel prompt appears without `client_id`. With `client_id`, the heading and the client's defaults show, ordered by product, with edit and delete controls. Other clients' defaults are excluded, and the empty message shows when the client has none.
  - `create` responds with a stream that has the list and a reset form keeping zone and client, and errors return 422.
  - `edit` renders the modal frame with read-only zone and client.
  - `update` changes product and quantity and ignores `zone_id` and `client_id`. It streams `_row` or `_panel_item` depending on `context`, and a duplicate returns 422.
  - `destroy` streams a remove.
  - The index rows have `dom_id` and an Editar button that opens the modal.

  Adjust the examples that expected redirects. Verify the file passes.

## 5. Verification

- [x] 5.1 Run `bundle exec rspec` and `bin/rubocop` on the changed Ruby files. Confirm 0 failures and no new offenses.
- [x] 5.2 Headless Chromium against a temporary server:
  - Default new: choose a zone and client, and the panel lists their defaults. Create two in a row and both appear, with the client kept. A duplicate shows an error. Edit from the panel in the modal, and delete from the panel.
  - Default index: Editar opens the modal, save updates the row, and delete removes the row.
  - Pendientes: the edit modal and the new-page panel still work after the rename.
- [x] 5.3 The user confirms both screens in their browser.
