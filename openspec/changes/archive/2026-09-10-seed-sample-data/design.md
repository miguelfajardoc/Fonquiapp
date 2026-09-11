## Context

`db/seeds.rb` is still the Rails-generated placeholder. The models it needs to
seed — `Zone`, `Client`, `Product`, `PendingProduct`, `DefaultProductQuantity`
— already exist with the validations and unique constraints described in the
`client-directory`, `product-catalog` and `product-ordering` specs (notably:
`Zone#name` and `Product#name` are unique; `DefaultProductQuantity` is unique
per `product_id`+`client_id`+`zone_id`; every `Client`/`PendingProduct`/
`DefaultProductQuantity` reference is required). See proposal.md — Why and What
Changes for scope; the confirmed decisions there are not repeated here.

## Goals / Non-Goals

**Goals:**

- A single idempotent `db/seeds.rb` that produces exactly 3 zones, 4 products, 6
  clients, 12 default product quantities and 5 pending products, matching the
  quantities and state split the user asked for.
- Never trip the unique constraints on `Zone#name`, `Product#name`, or
  `DefaultProductQuantity`.

**Non-Goals:**

- No `DailyProductOrder` seeds (explicit request).
- No production seed data or environment guarding beyond what
  `db/seeds.rb` already runs under (`RAILS_ENV` as invoked).
- No new gem for address/name generation — Faker (already a dependency) plus a
  small hardcoded word list.

## Decisions

### D1. Zones and products are the idempotent, name-keyed part

`Zone.find_or_create_by!(name: name)` for `%w[Bosa Soacha Kennedy]`.
`Product.find_or_create_by!(name: name) { |p| p.price = rand(5_000..30_000) }`
for `["Queso", "Suero", "Mantequilla", "Crema de leche"]` — the block only runs
on creation, so a rerun does not re-randomize an existing product's price.
Prices are whole pesos (no cents), matching how COP amounts are normally
written.

### D2. Clients are topped up per zone, not re-keyed by name

Client names are randomly generated (see D3), so they have no stable natural
key to `find_or_create_by` against. Seeding therefore does, per zone:
`clients_needed = 2 - zone.clients.count; clients_needed.times { create a client }`.
A first run creates 2 per zone (6 total); a rerun sees 2 already there and
creates none — safe, but it does **not** refresh previously seeded clients'
random data. This is the one place idempotency means "don't over-create"
rather than "regenerate," which is called out here because it differs from how
D1 and D4 behave.

### D3. Client name and address generation

Name: a prefix from
`%w[Salsamentaria Tienda Autoservicio Supermercado Distribuidora]` combined
with a short place-like suffix (e.g. `Faker::Address.community` or a small
hardcoded list such as "La Esperanza", "El Paisa", "San José", "La 42",
"Doña Rosa") — e.g. "Salsamentaria La Esperanza". No uniqueness is required
(`Client#name` has no uniqueness validation).
Address: `"#{%w[Calle Carrera Avenida].sample} #{rand(1..170)} # #{rand(1..99)}-#{rand(1..99)}, Bogotá y alrededores"`
for every client, regardless of zone — confirmed with the user: the zone name
is a label, not a geographic claim.
URL: a Google Maps text-search deep link built from that address —
`"https://www.google.com/maps/search/?api=1&query=#{ERB::Util.url_encode(address)}"`.
This needs no API key and no network call at seed time; it just opens Maps'
search on that address string when clicked. `phone` is a
`Faker::PhoneNumber.phone_number`.

### D4. Default product quantities: sample, don't retry

With `zone_id` fixed to the client's own zone (confirmed), the tuple
`(product, client)` alone determines `(product, client, zone)`, so uniqueness
only depends on not repeating a `(product, client)` pair. Build the full list of
`clients × products` (6 × 4 = 24 pairs) and take `sample(12)` — a
without-replacement sample of 12 distinct pairs (RuboCop's `Style/Sample` cop
prefers this over `shuffle.first(12)`; same guarantee) — this makes the unique
constraint unreachable by construction, so no rescue/retry loop is needed.
Quantity is `rand(1..10)` per row. Regenerated every run:
`DefaultProductQuantity.delete_all` first, then create the 12.

### D5. Pending products: fixed state split, random client and product

Build the array `%i[delivered delivered pending pending canceled]`, `shuffle`
it, and pair each state with an independently random client and an
independently random product (`rand(1..5)` quantity). `PendingProduct` has no
uniqueness constraint, so repeated client/product combinations across the 5
rows are fine. Regenerated every run: `PendingProduct.delete_all` first, then
create the 5.

### D6. Ordering inside `db/seeds.rb`

Zones, then products, then clients (needs zones), then default product
quantities and pending products (need clients and products). This mirrors the
FK dependency order from the `add-zone-client-models` and
`add-product-ordering-models` migrations.

## Risks / Trade-offs

- Client reruns don't refresh data (D2) → acceptable; deleting the 6 seeded
  clients manually (`Client.delete_all`, which cascades via the restrict guards
  only if nothing else references them) and rerunning regenerates fresh ones.
- The Google Maps link (D3) is a plain search URL, not a verified geocoded pin —
  good enough for "if possible", but it will not always land on the exact
  building.
- `shuffle.first(12)` (D4) assumes at least 12 of the 24 pairs exist, which is
  guaranteed here (6 clients × 4 products, fixed) but would need revisiting if
  either count changes later.

## Migration Plan

Not applicable — no schema change. Running `bin/rails db:seed` (or `db:setup`)
executes the script directly; no migration or rollback is involved.

## Open Questions

None. All decisions above were either confirmed with the user or are
cosmetic (exact name/address wording) with no effect on scope or acceptance.
