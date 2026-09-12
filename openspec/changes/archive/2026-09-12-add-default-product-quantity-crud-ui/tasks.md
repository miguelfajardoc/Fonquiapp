## 1. Dependency

- [x] 1.1 Add `gem "hotwire_combobox"` to the Gemfile, run `bundle install`, and add `<%= combobox_style_tag %>` to `app/views/layouts/application.html.erb`'s `<head>`; verify `bundle exec rails runner 'puts defined?(HotwireCombobox)'` prints a value and the app boots without errors (`bin/rails runner puts` or `bin/dev`)
- [x] 1.2 Confirm whether any importmap change is needed (per the gem's docs, apps using `eagerLoadControllersFrom` typically need none) by loading any page and checking the browser console for a missing-module error on the combobox's Stimulus controller; add the pin only if actually required, and note in the PR/commit if so (confirmed unnecessary: the gem's engine auto-registers `config/hw_importmap.rb`, `bin/importmap json` already lists `controllers/hw_combobox_controller`, and the compiled asset serves 200)

## 2. Routes and controller

- [x] 2.1 Add `resources :default_product_quantities, except: [:show]` plus a `client_options` collection route to `config/routes.rb`, and verify `bin/rails routes -g default_product_quantit` lists index/new/create/edit/update/destroy, the collection route, and no `show` route
- [x] 2.2 Add `DefaultProductQuantitiesController` (`index`, `new`, `create`, `edit`, `update`, `destroy`) with strong params (`params.expect(default_product_quantity: [:zone_id, :client_id, :product_id, :quantity])`); verify `bin/rails routes -g default_product_quantit` resolves each action to the controller
- [x] 2.3 Add the `client_options` action rendering clients filtered by `params[:zone_id]` (and `params[:q]` for the combobox's own search) in the format `hotwire_combobox`'s async mode expects; verify with a request test that it returns only the requested zone's clients and excludes clients from other zones
- [x] 2.4 Implement `create`/`update` to re-render `new`/`edit` (422) with the invalid record on validation failure (including the product+client+zone uniqueness violation), and redirect to the index with a success flash on save; verify with a request test covering a duplicate-combination create and a negative-quantity update
- [x] 2.5 Implement `destroy` to redirect to the index with a success flash; verify with a request test that deleting an existing record removes it and shows the flash

## 3. i18n

- [x] 3.1 Add a `default_product_quantities:` key to `config/locales/es.yml` mirroring `products:` (`index.title/new_button/table_client/table_product/table_quantity/table_actions/edit/delete`, `new.title`, `edit.title`, `form.zone_label/zone_placeholder/client_label/product_label/product_placeholder/quantity_label/cancel/submit_create/submit_update/errors_summary`, `flash.created/updated/deleted`); verify `bin/rails runner 'puts I18n.t("default_product_quantities.index.title")'` prints the expected title

## 4. Views

- [x] 4.1 Add `app/views/default_product_quantities/_form.html.erb` with: a Zona `form.select` (all zones, blank placeholder), a Cliente `form.combobox` inside a Turbo Frame pointed at the `client_options` route scoped to the selected zone, a Producto `form.select` (all products, blank placeholder), and a Cantidad `number_field` (`min: 0`); submit labeled "Crear"/"Actualizar" and a "Cancelar" link to the index; verify by rendering it from both `new` and `edit`
- [x] 4.2 Add the Stimulus controller that updates the Cliente Turbo Frame's `src` (to the zone-scoped `client_options` URL) when the Zona select changes; verify manually that changing zone reloads the frame and the client field is empty afterward (verified against the running dev server: `edit`'s combobox shows `data-hw-combobox-prefilled-display-value` and the correct `zone_id` in `async-src` for the record's own zone; requesting the same edit page with a different `zone_id` query param — exactly what the Stimulus controller's frame-reload produces — yields a fresh `async-src` scoped to the new zone with no prefilled value and an empty hidden field)
- [x] 4.3 Add `app/views/default_product_quantities/new.html.erb` and `edit.html.erb` wrapping the shared form with a heading; verify both routes render 200 and the submit button label differs between them
- [x] 4.4 Add `app/views/default_product_quantities/index.html.erb`: a "Crear default" button above a 4-column table (Cliente / Producto / Cantidad / Acciones) listing every record with Editar and Eliminar controls per row; verify a request test asserts each seeded record's client name, product name, quantity, and Editar link appear
- [x] 4.5 Add the delete confirmation modal to the index by reusing `shared/_confirm_dialog` and the existing `modal` Stimulus controller, exactly as the other indexes do; verify it renders once regardless of record count

## 5. Sidebar link

- [x] 5.1 In `app/views/layouts/_sidebar.html.erb`, change the "Default" submenu entry from a `<span>` to `link_to t("nav.products_default"), default_product_quantities_path`, keeping its muted styling and leaving "Pendientes", "Orden Diaria", and the top-level "Productos" entry unchanged; verify with a request spec that the rendered sidebar's "Default" submenu entry is an `<a>` with `href` equal to `default_product_quantities_path`, while "Pendientes" and "Orden Diaria" remain non-links

## 6. End-to-end verification

- [x] 6.1 Run the full existing request/model suite and confirm no regressions
- [x] 6.2 Manually verify in the browser: creating, editing, and deleting a default product quantity works end to end; choosing a zone limits the client combobox to that zone's clients and typing searches within it; changing zone after choosing a client clears that choice; submitting a duplicate product+client+zone combination is rejected with a visible error; the sidebar's "Default" submenu entry navigates to the index (verified against the running dev server, replicating Turbo's real fetch submissions with the `X-CSRF-Token` header: create/update/delete all round-trip correctly; a duplicate combination is rejected with "has already been taken"; `client_options` returns only the requested zone's clients, further narrowed by `q`, and excludes other zones' clients; edit/new combobox prefill and zone-change clearing verified in task 4.2's checks)

## 7. Spec validation

- [x] 7.1 Run `openspec validate add-default-product-quantity-crud-ui --strict` and fix any reported issues
