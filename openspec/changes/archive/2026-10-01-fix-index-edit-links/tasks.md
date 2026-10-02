## 1. Edit links break out of the table frame

- [x] 1.1 Add `data: { turbo_frame: "_top" }` to the edit `link_to` in `app/views/products/index.html.erb` and `app/views/default_product_quantities/index.html.erb`
- [x] 1.2 In `spec/requests/products_spec.rb` and `spec/requests/default_product_quantities_spec.rb`, assert that each row's "Editar" link inside the table frame points to the edit path and has `data-turbo-frame="_top"`. Verify both files pass.

## 2. Client "Editar" button

- [x] 2.1 In `app/views/clients/index.html.erb`, put an "Editar" link (`edit_client_path`, `data-turbo-frame="_top"`, same styling as the other indexes) next to "Eliminar" inside the actions cell, which already has `data-row-target="skip"`. Wrap both in `div.flex.gap-3`. Add `clients.index.edit` to `es.yml`.
- [x] 2.2 In `spec/requests/clients_spec.rb`, assert that each client row has an "Editar" link to `edit_client_path(client)` with `data-turbo-frame="_top"`, inside the `data-row-target="skip"` cell. Verify the file passes.

## 3. Verification

- [x] 3.1 Run `bundle exec rspec` and `bin/rubocop` on the changed Ruby files. Confirm 0 failures and no new offenses.
- [x] 3.2 Run the scratchpad headless-Chromium script against a temporary server:
  - On a filtered Productos and Default list, "Editar" lands on the edit page.
  - On Clientes, "Editar" lands on `/clients/:id/edit`, not the detail page.
  - On Pendientes, "Editar" opens the modal and saving updates the row.
  - No Turbo frame-missing error in any of them.
- [x] 3.3 In the user's browser, after reloading, confirm "Editar" works on Productos, Default, Clientes, and Pendientes.
