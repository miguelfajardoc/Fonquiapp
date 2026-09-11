## Why

The four domain models (`Zone`, `Client`, `Product`, `PendingProduct`,
`DefaultProductQuantity`) exist but the development database is empty, so there
is nothing to exercise them against in the console, in manual testing, or in a
future UI. `db/seeds.rb` should populate a small, realistic dataset.

## What Changes

- Populate `db/seeds.rb` to create, idempotently:
  - 3 **zones**: Bosa, Soacha, Kennedy.
  - 4 **products**: Queso, Suero, Mantequilla, Crema de leche — each with a
    random price between 5,000 and 30,000 (COP, whole pesos).
  - 6 **clients** (2 per zone) — random salsamentaria/tienda-style names, a
    random Bogotá-area street address, and a Google Maps search URL built from
    that address.
  - 12 **default product quantities** — a random product for a random client,
    quantity 1–10, at most one row per product+client combination (so the
    product+client+zone unique constraint is never at risk).
  - 5 **pending products** — a random client and a random product each, quantity
    1–5, with a fixed split of 2 `delivered`, 2 `pending`, 1 `canceled`.
- **No seeds for `DailyProductOrder`** — deliberately left empty, per the
  request.
- `db/seeds.rb` is safe to run more than once: zones and products are looked up
  or created by their fixed name; each zone is topped up to 2 clients only if it
  has fewer (client names are random, so they have no natural key to
  re-match — reruns never fabricate a 3rd/4th client per zone, but also don't
  refresh already-seeded client data); the quantity/pending tables are cleared
  and regenerated on every run so their counts stay exactly 12 and 5.
- **Out of scope:** no changes to models, migrations, controllers, routes, or
  any other application code — only `db/seeds.rb`.

### Decisions confirmed with the user

- Client addresses read "Bogotá y alrededores" for every client regardless of
  zone — the zone name is a label, not a geographic claim, so Soacha's clients
  are not given a separate "Soacha, Cundinamarca" address.
- `zone_id` on `DefaultProductQuantity` and `PendingProduct` is always the
  chosen client's own zone.
- `PendingProduct` picks a random product per row (not tied to the quantity
  rows).
- The script is idempotent (matches `db/seeds.rb`'s own header comment).

## Capabilities

### New Capabilities
<!-- none — this is a data-seeding script, not a system behavior. skip_specs: true is set in .openspec.yaml. -->

### Modified Capabilities
<!-- none — no model, validation, or association changes; client-directory, product-catalog and product-ordering are unaffected. -->

## Impact

- **Changed code:** `db/seeds.rb` only.
- **Data:** running `bin/rails db:seed` creates/refreshes 3 zones, 4 products, 6
  clients, 12 default product quantities and 5 pending products in whatever
  database `RAILS_ENV` points at. No production data is targeted by this change
  (it is meant for development).
- **No** changes to schema, models, routes, or dependencies.
