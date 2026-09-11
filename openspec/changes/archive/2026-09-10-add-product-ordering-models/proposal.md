## Why

The ERP can record clients and zones (see the `client-directory` capability) but
has nothing about *what* those clients receive. This change adds the product
catalogue and the three per-client/zone quantity records the business works
with: standing defaults, day-by-day orders, and still-pending deliveries.

## What Changes

- Add a **`Product`** record (`products` table): `name` (string) and `price`
  (money).
- Add **`PendingProduct`** (`pending_products` table): `quantity` (integer), a
  `state` enum (`pending` / `delivered` / `canceled`), and required references to
  a product, a client and a zone.
- Add **`DefaultProductQuantity`** (`default_product_quantities` table): required
  references to a product, a client and a zone, plus a `quantity` (integer). One
  row per product+client+zone combination (enforced by a unique index).
- Add **`DailyProductOrder`** (`daily_product_orders` table): required references
  to a product, a client and a zone, a `quantity` (integer) and a `day`.
- Wire the associations: each new model `belongs_to` its product, client and
  zone; `Product`, `Client` and `Zone` gain the reciprocal `has_many` for
  navigation. Every reference is backed by a database foreign key.
- Add a FactoryBot factory and a model spec for each of the four models, per the
  project's RSpec convention.
- **Out of scope:** controllers, routes, views, JSON/serializers, jobs, seeds,
  policies, admin screens, and any money/currency gem. Models + migrations +
  specs only.

### Decisions applied from the request (confirmed with the user)

- **`Product#price` is `decimal(10, 2)`, not `float`.** The request annotated it
  "float (money)"; floating point is unsafe for money, so the column is a
  fixed-scale decimal.
- **`DailyProductOrder#day` is a `date`, not `datetime`.** "Daily order" is a
  calendar day; the request said `datetime`.
- **Unique index only on `DefaultProductQuantity`** over
  `(product_id, client_id, zone_id)`. `PendingProduct` and `DailyProductOrder`
  allow repeats.

## Capabilities

### New Capabilities
- `product-catalog`: the `Product` master record — the sellable/deliverable
  items, their name and their price, and the rules that keep those records
  well-formed.
- `product-ordering`: the per-client/zone product-quantity records —
  `PendingProduct`, `DefaultProductQuantity` and `DailyProductOrder` — their
  fields, the `PendingProduct` lifecycle states, the required product/client/zone
  links with referential integrity, and the one-default-per-combination rule.

### Modified Capabilities
<!-- none. client-directory is untouched: the new has_many associations on Client
     and Zone carry no dependent: option, so those models' specified deletion
     behavior does not change. Parent-deletion integrity for the new tables is
     enforced by database foreign keys. -->

## Impact

- **New code:** `app/models/product.rb`, `app/models/pending_product.rb`,
  `app/models/default_product_quantity.rb`, `app/models/daily_product_order.rb`;
  four migrations under `db/migrate/`; added `has_many` lines in
  `app/models/product.rb` (new), `app/models/client.rb`, `app/models/zone.rb`;
  regenerated `db/schema.rb`.
- **New tests:** a factory and a `spec/models/*_spec.rb` for each of the four
  models.
- **Database:** four new tables, nine foreign-key constraints, one composite
  unique index, plus the per-column FK indexes. No data migration or backfill.
- **No** changes to routing, HTTP, dependencies, or configuration.
- `Client` and `Zone` now raise `ActiveRecord::InvalidForeignKey` on deletion
  while any of the new records reference them (previously only `Client` rows
  blocked a `Zone` deletion, and with a validation error).
