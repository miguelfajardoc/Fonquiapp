## 1. Routes and controller

- [x] 1.1 Add `resources :products, except: [:show]` to `config/routes.rb` and verify `bin/rails routes -g product` lists index/new/create/edit/update/destroy and no `show`/`product#show` route
- [x] 1.2 Add `ProductsController` (`index`, `new`, `create`, `edit`, `update`, `destroy`) with strong params (`params.expect(product: [:name, :price])`) and verify `bin/rails routes -g product` resolves each action to `ProductsController`
- [x] 1.3 Implement `create`/`update` to re-render `new`/`edit` (422) with `@product` on validation failure, and redirect to `products_path` with a success flash on save; verify with a request test covering a blank-name create and a negative-price update
- [x] 1.4 Implement `destroy` to redirect to `products_path` with a success flash when `product.destroy` returns true, and with a flash built from `@product.errors.full_messages` when it returns false; verify with a request test that destroys a product with an associated pending product and asserts the product still exists and the flash is present

## 2. i18n and currency formatting

- [x] 2.1 Add a `products:` key to `config/locales/es.yml` mirroring `zones:` (`index.title/new_button/table_name/table_price/table_actions/edit/delete`, `new.title`, `edit.title`, `form.name_label/price_label/cancel/submit_create/submit_update/errors_summary`, `flash.created/updated/deleted`); verify `bin/rails runner 'puts I18n.t("products.index.title")'` prints "Productos"
- [x] 2.2 Add an `es.number.currency.format` entry (`unit: "$"`, `delimiter: "."`, `separator: ","`, `precision: 0`) to `config/locales/es.yml`; verify `bin/rails runner 'puts ActionController::Base.helpers.number_to_currency(12345)'` prints `$12.345` (no decimals)

## 3. Views

- [x] 3.1 Add `app/views/products/_form.html.erb` with `name` (text) and `price` (`number_field`, `min: 0`, `step: 1`) fields, a submit button labeled "Crear" for a new record and "Actualizar" for a persisted one, and a "Cancelar" link to `products_path`; verify by rendering it from both `new` and `edit`
- [x] 3.2 Add `app/views/products/new.html.erb` and `app/views/products/edit.html.erb` wrapping the shared form with a heading; verify both routes render 200 and the submit button label differs between them
- [x] 3.3 Add `app/views/products/index.html.erb`: a "Crear producto" button above a 3-column table (Nombre / Precio / Acciones) listing every product with Editar and Eliminar controls per row, price rendered via `number_to_currency`; verify a request test asserts each seeded product's name, its formatted price (no decimals), and its Editar link appear
- [x] 3.4 Add the delete confirmation modal to `products/index.html.erb` by reusing `shared/_confirm_dialog` and the existing `modal` Stimulus controller, exactly as `zones/index.html.erb` does; verify it renders once regardless of product count

## 4. Sidebar link

- [x] 4.1 In `app/views/layouts/_sidebar.html.erb`, change the "Productos" submenu entry from a `<span>` to `link_to t("nav.products"), products_path`, keeping its muted styling and leaving the other three submenu entries and the top-level "Productos" entry unchanged; verify with a request spec that the rendered sidebar's "Productos" submenu entry is an `<a>` with `href` equal to `products_path`, while "Default", "Pendientes", and "Orden Diaria" remain non-links

## 5. End-to-end verification

- [x] 5.1 Run the full existing request/model suite and confirm no regressions (`spec/requests/zones_spec.rb`, `spec/requests/clients_spec.rb`, `spec/requests/app_shell_spec.rb`, model specs)
- [x] 5.2 Manually verify in the browser: creating, editing, and deleting a product from the index works end to end; deleting a product referenced by a pending product/default quantity/daily order is blocked with a flash; the sidebar's "Productos" submenu entry navigates to the product index (verified against the running dev server: create/edit/index-formatting/sidebar-link via curl, and deletion — both allowed and blocked-by-association — via curl reproducing Turbo's actual fetch submission, i.e. including the `X-CSRF-Token` header from the page's meta tag; also confirmed working directly by the user in the browser for products, a client, and a zone)

## 6. Spec validation

- [x] 6.1 Run `openspec validate add-product-crud-ui --strict` and fix any reported issues
