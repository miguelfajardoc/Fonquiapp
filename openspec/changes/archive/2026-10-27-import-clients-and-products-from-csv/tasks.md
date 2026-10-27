## 1. Client name rule and seeds

- [x] 1.1 Add the case- and accent-insensitive name uniqueness validation to `Client` (same `taken` message as the app's other uniqueness rules, which are not translated yet); verify `spec/models/client_spec.rb` covers "name already used by another client" (any zone, different case and accents) and "a client keeps its own name when updated", and passes
- [x] 1.2 Add request specs for creating and renaming a client to a name in use (form re-rendered with the error, nothing saved); verify `spec/requests/clients_spec.rb` passes
- [x] 1.3 Make `db/seeds/development.rb` pick distinct client names from the shuffled prefix × suffix combinations, skipping names already used; verify `bin/rails db:reset` twice in a row succeeds and `spec/db/seeds_spec.rb` passes

## 2. Shared CSV reading

- [x] 2.1 Add `gem "csv"` to the Gemfile and run `bundle install`; verify `bin/rails runner 'require "csv"; puts CSV::VERSION'` works
- [x] 2.2 Implement `CsvImport` (file presence and 2 MB cap, BOM strip, Windows-1252 fallback, normalized headers, required-header check, malformed CSV, per-row `lineno`, `Result` with created/updated/failures, `InvalidFile` and `RowError`) with Spanish messages in `es.yml`; verify `spec/services/csv_import_spec.rb` covers each case and passes

## 3. Coordinates from Google Maps URLs

- [x] 3.1 Add `GoogleMaps.coordinates_from_url` and `GoogleMaps.resolve_short_link` (short-link hosts only, max 3 hops, 3 s timeouts, errors return nil; patterns `!3d!4d`, `@lat,lng`, `query`/`q`/`ll`; range check); verify `spec/services/google_maps_spec.rb` covers full links, a stubbed short link, unreadable links, out-of-range values, and that no request is made for other hosts, and passes

## 4. Client import

- [x] 4.1 Implement `ClientCsvImport` (required `name`, `address`, `zone`; zone and route find-or-create ignoring case and accents; client appended as last route stop; one transaction per row; location from the url only); verify `spec/services/client_csv_import_spec.rb` covers every "Creating clients from rows" and "Client location from the URL" scenario and passes
- [x] 4.2 Add `POST /clients/import` and `ClientsController#import` (notice with created count; alert array of at most 20 "Fila N: motivo" lines plus "y N filas más"; `InvalidFile` and missing file as a single alert); verify request specs for the import result scenarios pass

## 5. Product import

- [x] 5.1 Implement `ProductCsvImport` (required `name` and `price`, price format check, find by name ignoring case and accents, update price or create); verify `spec/services/product_csv_import_spec.rb` covers every "Creating and updating products from rows" scenario and passes
- [x] 5.2 Add `POST /products/import` and `ProductsController#import` (notice with created and updated counts; failures alert as for clients); verify request specs for the product import result scenarios pass

## 6. Upload control and flash

- [x] 6.1 Add `shared/_import_button.html.erb` (multipart form with `auto-submit`, label-styled button wrapping a hidden `.csv` file input) and render it to the right of "Crear cliente" and "Crear producto" inside a `flex gap-3` group; update the header assertions in `spec/requests/clients_spec.rb` and `spec/requests/products_spec.rb` (they look for the create link as a direct child) and add assertions for the import control; verify both specs pass
- [x] 6.2 Render array flash messages as a list in `layouts/_flash.html.erb`; verify a request spec shows each failed row as its own list item
- [x] 6.3 Check in the headless browser, on both indexes: the import button sits right of the create button, clicking it opens the file picker (file chooser event), choosing a CSV with valid, invalid and duplicate rows submits it, and the flash shows the counts and the failed lines as a list

## 7. Wrap-up

- [x] 7.1 Run `bundle exec rspec` and `bin/rubocop`; verify both pass
