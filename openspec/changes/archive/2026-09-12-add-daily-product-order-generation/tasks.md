## 1. Setup

- [x] 1.1 Add `caxlsx` to the Gemfile and run `bundle install`; verify `Axlsx::Package.new` is loadable from `bin/rails runner` (the gem's public API lives under the `Axlsx` module, not `Caxlsx` — confirmed by reading the gem source)
- [x] 1.2 Create `app/services/` and confirm Zeitwerk autoloads it (no explicit `autoload_paths` entry needed since it follows the standard `app/*` convention) by referencing a placeholder class from `bin/rails runner`

## 2. Generation service

- [x] 2.1 Add `app/services/daily_product_order_generation.rb`: `.new(zone:, day: Date.current).call` sums `DefaultProductQuantity.where(zone:)` and `PendingProduct.where(zone:, state: :pending)` quantities grouped by `[client_id, product_id]`, skipping zero totals
- [x] 2.2 Wrap the write in a transaction that deletes existing `DailyProductOrder` rows for that `zone`+`day` before creating the newly computed ones
- [x] 2.3 Spec (`spec/services/daily_product_order_generation_spec.rb`) covering: combines default + pending quantities (per spec scenario); excludes `delivered`/`canceled` pending products; produces no record for a zero total; excludes other zones' clients; regenerating the same zone+day replaces prior records; a different day's batch for the same zone is untouched

## 3. Consolidation service

- [x] 3.1 Add `app/services/daily_product_order_consolidation.rb`: `.new(zone:, day:).call` returns an `Axlsx::Package` with one worksheet — a header/client-rows table (Cliente, Dirección, Ubicación as a formula cell via `escape_formulas: false`, then dynamic "Pendiente N" columns sized to the widest zone client's *current* `pending`-state pending product count) for every client in the zone (present even with nothing due, per the fix after manual testing), followed by a blank row and a Producto/Cantidad table summing that batch's stored `DailyProductOrder` quantities per product
- [x] 3.2 Spec (`spec/services/daily_product_order_consolidation_spec.rb`) covering: a client's row includes name/address/hyperlink formula and one column per current pending product formatted `"<product>: <quantity>"`; a client with no current pending products gets no pending columns; the product totals table sums quantities across the batch's clients; changing default/pending data after generation does not change the downloaded totals (reads the stored `DailyProductOrder` rows, not live data)

## 4. Routes and controller

- [x] 4.1 Add to `config/routes.rb`: `resources :daily_product_orders, only: [:index]` plus collection routes `post :generate` and `get :consolidated`; verify `bin/rails routes -g daily_product_order` shows index/generate/consolidated and no show/new/create/edit/update/destroy routes
- [x] 4.2 Add `DailyProductOrdersController#index`: loads `@zones` (for the filter `<select>`) and `@batches` (distinct day+zone pairs, newest first, per design.md)
- [x] 4.3 Add `#generate`: requires `params[:zone_id]`, redirects back with an error flash if blank; otherwise calls `DailyProductOrderGeneration` and redirects to the index with a success flash
- [x] 4.4 Add `#consolidated`: loads the zone and day from params, calls `DailyProductOrderConsolidation`, and streams the result via `send_data` with an `.xlsx` filename and the correct spreadsheet MIME type
- [x] 4.5 Request spec (`spec/requests/daily_product_orders_spec.rb`) covering: index renders the zone filter and lists existing batches grouped one row per day+zone; generating without a zone chosen shows an error and creates nothing; generating with a zone creates the expected records and redirects with a notice; the consolidated download responds with the spreadsheet MIME type and a body containing the expected client/product content

## 5. Index view

- [x] 5.1 Add `app/views/daily_product_orders/index.html.erb`: a zone `<select>` + "Generar" button (submitting to `#generate`) styled like the other index pages' forms, and below it a table (Día, Zona, Acción) listing `@batches`, each row's Acción holding a "Descargar consolidado" link/button to `#consolidated` for that row's day+zone, with `data: { turbo: false }` on that link so Turbo Drive doesn't wait on a page-visit signal that a file download never sends (see design.md)
- [x] 5.2 Request spec assertion (can extend 4.5): the "Generar" control and, for each listed batch, a "Descargar consolidado" control pointing at that batch's `consolidated` URL are present in the rendered index

## 6. Sidebar and i18n

- [x] 6.1 Update `app/views/layouts/_sidebar.html.erb`: turn the "Orden Diaria" submenu entry into a link to `daily_product_orders_path`, matching the other three submenu links
- [x] 6.2 Update `spec/requests/app_shell_spec.rb`'s submenu test: all four submenu entries are now links (drop the "remaining entries are inert" assertion, add "Orden Diaria" to the linked entries with its expected href)
- [x] 6.3 Add a `daily_product_orders` namespace to `config/locales/es.yml` (index title, zone filter label/placeholder, "Generar" button, table headers Día/Zona/Acción, "Descargar consolidado" button, flash messages for missing-zone error and successful generation)

## 7. Full verification

- [x] 7.1 Run the full test suite (`bin/rspec`) and `rubocop`, and fix any failures/offenses
- [x] 7.2 Manually verify against the running dev server: generate a zone with a client that has both a default quantity and a pending product, confirm the summed `DailyProductOrder` and its listing row appear; regenerate the same zone/day after changing the default quantity and confirm the batch is replaced, not duplicated; download the consolidated spreadsheet and open it to confirm the client table (with a working location hyperlink and pending columns) and the product totals table look correct; confirm the sidebar's "Orden Diaria" link navigates to the index
