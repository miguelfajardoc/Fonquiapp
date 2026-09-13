## 1. Routes and controller

- [x] 1.1 Add `resources :pending_products, except: [:show]` with a `patch :toggle_state` member route and a `get :client_options` collection route to `config/routes.rb`; verify `bin/rails routes -g pending_product` lists index/new/create/edit/update/destroy/toggle_state/client_options and no show route
- [x] 1.2 Create `PendingProductsController` with `index`, `new`, `create`, `edit`, `update`, `destroy`, `toggle_state`, and `client_options` actions, using `params.expect(...)` for strong params; `new`/`create` derive `zone_id` from the chosen client and default `state` to `pending`
- [x] 1.3 Add `to_combobox_display` is already present on `Client` (added for default-product-quantity); confirm no change needed there

## 2. Shared view partials

- [x] 2.1 Add `app/views/pending_products/_row.html.erb` (`<tr>`, index table) and `_panel_item.html.erb` (div/grid row, create page's non-table list), each wrapped in `dom_id(pending_product)`, showing creation date (`strftime("%d/%m/%Y")`), product name, quantity, a state badge, and Editar/Eliminar/toggle controls via a shared `_actions.html.erb` partial (`_row` also shows client name; `_panel_item` omits it since the panel is already scoped to one client)
- [x] 2.2 Add a `_state_badge.html.erb` partial rendering "Pendiente" and "Entregado" with distinct colors (accent token for Pendiente, new delivered token for Entregado) and "Cancelado" with no highlight color
- [x] 2.3 Add `app/views/shared/_pending_product_edit_modal.html.erb`: a `<dialog>` (styled like `shared/_confirm_dialog`) containing an empty `turbo_frame_tag "pending_product_edit_modal"`, rendered once per page (index and create)
- [x] 2.4 Add `app/javascript/controllers/pending_product_edit_modal_controller.js` with `open` (sets the frame's `src`, shows the dialog), `close`, and `submitEnd` (closes the dialog on a successful `turbo:submit-end` bubbled from the frame's form)

## 3. Create form and combobox

- [x] 3.1 Add `app/views/pending_products/_form.html.erb`: client combobox (`client_options_pending_products_path`), product `<select>`, quantity number field, crear/cancelar buttons, matching the existing form styling
- [x] 3.2 Add `app/javascript/controllers/pending_product_client_filter_controller.js`: listens for `hw-combobox:selection`/`hw-combobox:removal` (bubbled from a wrapper around the combobox) and sets a `turbo_frame_tag "pending_product_client_panel"`'s `src` to `new_pending_product_path` with/without `client_id`
- [x] 3.3 `PendingProductsController#new` reads `params[:client_id]`, loading `@selected_client` and `@client_pending_products` (newest first) when present
- [x] 3.4 `PendingProductsController#client_options` returns clients (unscoped by zone), optionally filtered by `q`, via `hw_async_combobox_options`, mirroring `DefaultProductQuantitiesController#client_options` minus the zone filter

## 4. Create page: live client-scoped list

- [x] 4.1 Add `app/views/pending_products/new.html.erb`, `_client_panel.html.erb` (heading "Pendientes Cliente <nombre>" or the choose-a-client empty state), and `_client_pending_list.html.erb` (the `dom_id(client, :pending_products)`-wrapped list of `_panel_item`s, or a "no pending products" message), wired into the `pending_product_client_panel` turbo-frame
- [x] 4.2 `PendingProductsController#create` (success): sets `zone_id`/`state` as designed, responds with a multi-part `turbo_stream` — replace `dom_id(@selected_client, :pending_products)` with the freshly queried `_client_pending_list` and replace the form partial with a blank one — and verify via a request spec asserting both stream actions are present
- [x] 4.3 `PendingProductsController#create` (failure): responds with `turbo_stream.replace` of the form partial showing errors, status `:unprocessable_content`; verify via a request spec

## 5. Editing via the shared modal

- [x] 5.1 `PendingProductsController#edit` renders `edit.html.erb` (client/product/quantity form, same fields as create) wrapped in `turbo_frame_tag "pending_product_edit_modal"`, `layout: false`
- [x] 5.2 `PendingProductsController#update` (success): `turbo_stream.replace` targeting `dom_id(pending_product)` with the updated row partial; (failure): re-render `edit.html.erb` in the same frame with status `:unprocessable_content`
- [x] 5.3 Wire each row's Editar button to `pending-product-edit-modal#open` with the record's `edit_pending_product_path` as the url param
- [x] 5.4 Request spec: editing a record from a request that simulates the modal's turbo-frame submission returns a stream replacing the correct row id; editing with invalid data returns the frame re-rendered with an error and status 422

## 6. State toggle

- [x] 6.1 `PendingProductsController#toggle_state` flips `pending` ⇄ `delivered` on the given record and responds with the same row-replace `turbo_stream` as `update`; only render the toggle control for non-`canceled` rows in `_row.html.erb`
- [x] 6.2 Request spec: toggling a `pending` record sets it to `delivered` and vice versa; the response replaces the row's dom id

## 7. Deletion

- [x] 7.1 Wire each row's Eliminar button to the existing `shared/_confirm_dialog` + `modal_controller` pattern (reused as-is, matching other resources)
- [x] 7.2 `PendingProductsController#destroy`: `turbo_stream.remove` targeting `dom_id(pending_product)`, with an `html` fallback (redirect to index with a flash notice)
- [x] 7.3 Request spec: confirming deletion removes the record and it no longer appears in `PendingProduct.all`; canceling the confirmation (no request sent) leaves it intact

## 8. Index page

- [x] 8.1 Add `app/views/pending_products/index.html.erb`: table using `_row.html.erb` for every pending product, "Crear Pendiente" button top-right, the shared edit modal partial, and the existing confirm dialog
- [x] 8.2 Request spec: index lists every record's date/client/product/quantity/state and provides create/edit/delete/toggle controls per row

## 9. Sidebar, i18n, and styling

- [x] 9.1 Update `app/views/layouts/_sidebar.html.erb`: turn the "Pendientes" submenu entry into a link to `pending_products_path`, matching "Productos"/"Default"
- [x] 9.2 Update `spec/requests/app_shell_spec.rb`'s submenu test to expect "Pendientes" as a link too (only "Orden Diaria" remains inert)
- [x] 9.3 Add a `pending_products` namespace to `config/locales/es.yml` (index/new/edit/form/flash/state labels: "Pendiente"/"Entregado"/"Cancelado")
- [x] 9.4 Add a `--state-delivered` token (light + dark) to `app/assets/tailwind/application.css`, exposed via `@theme`; rebuild with `bin/rails tailwindcss:build`

## 10. Full verification

- [x] 10.1 Run the full test suite (`bin/rspec`) and `rubocop`, and fix any failures/offenses
- [x] 10.2 Manually verify against the running dev server: create a pending product for a client (list appears live), switch clients (list swaps), toggle a state (badge updates in place, no reload), edit via modal from both index and the create page (updates in place, modal closes on success and stays open with an error on invalid input), delete with confirmation, and confirm the sidebar's "Pendientes" link navigates to the index
