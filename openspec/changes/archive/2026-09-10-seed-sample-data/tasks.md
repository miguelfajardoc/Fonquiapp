## 1. Zones and products

- [x] 1.1 In `db/seeds.rb`, seed the 3 zones (`Bosa`, `Soacha`, `Kennedy`) with `Zone.find_or_create_by!(name: name)`. Verify `bin/rails db:seed` run twice in a row leaves exactly 3 zones (`Zone.count == 3`) with no error.
- [x] 1.2 Seed the 4 products (`Queso`, `Suero`, `Mantequilla`, `Crema de leche`) with `Product.find_or_create_by!(name: name) { |p| p.price = rand(5_000..30_000) }`. Verify `Product.count == 4` after two runs, every price is between 5000 and 30000, and a product's price is unchanged on the second run.

## 2. Clients

- [x] 2.1 Add the name/address/URL/phone generator described in design.md D3 (business-type prefix + place suffix; `"Calle|Carrera|Avenida # #-# , Bogotá y alrededores"`; a Google Maps search URL built from that address with `ERB::Util.url_encode`; a Faker phone number). Verify in `bin/rails runner` that the generated address always ends in "Bogotá y alrededores" and the URL starts with `https://www.google.com/maps/search/?api=1&query=`.
- [x] 2.2 For each zone, create clients up to 2 (`2 - zone.clients.count`, per design.md D2) using that generator, each `belongs_to` that zone. Verify `bin/rails db:seed` run once yields `Client.count == 6` with exactly 2 per zone, and running it again leaves the count at 6 (no zone exceeds 2).

## 3. Default product quantities

- [x] 3.1 Build the 6×4 client/product pair list, `shuffle` and take the first 12 (design.md D4), and for each pair create a `DefaultProductQuantity` with `zone: pair_client.zone` and `quantity: rand(1..10)`, after `DefaultProductQuantity.delete_all`. Verify `bin/rails db:seed` leaves `DefaultProductQuantity.count == 12` with no repeated `(product_id, client_id, zone_id)` triple, every `zone_id` equal to its row's `client.zone_id`, and every `quantity` between 1 and 10; verify a second run still leaves exactly 12.

## 4. Pending products

- [x] 4.1 Build the fixed state array `%i[delivered delivered pending pending canceled]`, `shuffle` it, and for each state create a `PendingProduct` with an independently random client, an independently random product, `zone: that client's zone`, and `quantity: rand(1..5)`, after `PendingProduct.delete_all`. Verify `bin/rails db:seed` leaves `PendingProduct.count == 5` with exactly 2 `delivered`, 2 `pending`, 1 `canceled`, every `quantity` between 1 and 5, and every row's `zone_id` equal to its `client.zone_id`; verify a second run still leaves exactly 5 with the same state split.

## 5. Finalize

- [x] 5.1 Confirm no `DailyProductOrder` seeding was added (`DailyProductOrder.count == 0` after seeding a clean database).
- [x] 5.2 Run `bin/rails db:seed` twice in a row against the development database and verify it completes both times with no exception and the final counts are Zone 3, Product 4, Client 6, DefaultProductQuantity 12, PendingProduct 5, DailyProductOrder 0.
- [x] 5.3 Run `bin/rubocop -A` then `bin/rubocop` on `db/seeds.rb` and verify zero offenses; run `bin/brakeman -q` and verify zero warnings.
