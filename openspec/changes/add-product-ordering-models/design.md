## Context

Rails 8.1 on PostgreSQL. The `client-directory` capability already ships `Zone`
and `Client` (`zones`, `clients` tables; `Client belongs_to :zone`; `Zone
has_many :clients, dependent: :restrict_with_error`). RSpec + FactoryBot are
configured, and generated model/factory pairs are the norm. Project conventions
(openspec/project.md): logic in models or `app/services`, `bin/rubocop -A`
before committing. See proposal.md — Why for motivation; see the
`product-catalog` and `product-ordering` specs for the behaviour contract.

## Goals / Non-Goals

**Goals:**

- Four persisted records with integrity enforced at both the database and the
  model layer.
- A foreign-key graph that guarantees every ordering row points at a real
  product, client and zone.
- Factories and model specs covering every scenario in the two specs.

**Non-Goals:**

- No CRUD surface, seeds, serialization, jobs, or admin screens (proposal — Out
  of scope).
- No money/currency gem — `price` is a plain `decimal` column.
- No cross-field rule that `zone_id` must equal the referenced client's zone
  (see D7).
- No state-transition rules on `PendingProduct#state` — any state may be set
  directly (see D2).

## Decisions

### D1. `Product#price` is `decimal`, not `float`

Column `decimal(10, 2)`, `null: false`. Model: `validates :price, presence: true,
numericality: { greater_than_or_equal_to: 0 }`. The request wrote "float
(money)"; float loses precision on sums and comparisons. `10, 2` covers amounts
up to `99_999_999.99`. Confirmed with the user.
*Alternative — a Money gem (money-rails):* rejected as scope creep for a
models-only change; a decimal column is the minimal correct choice and a gem can
wrap it later.

### D2. `PendingProduct#state` is an integer enum

Column `state` `integer`, `null: false`, `default: 0`. Model:
`enum :state, { pending: 0, delivered: 1, canceled: 9 }`. Codes are exactly as
the request gave them (note the gap at 9 for `canceled`). US spelling
`canceled` kept as written. No state-transition rules are specified, so any
state may be set directly.

### D3. `DailyProductOrder#day` is a `date`

Column `day` `date`, `null: false`, `validates :day, presence: true`. "Daily
order" is a calendar day; the request said `datetime`. Confirmed with the user.
This also makes a future unique index on `(…, day)` feasible if it is ever
wanted (not added now — see D5).

### D4. All three references are required, with DB foreign keys and indexes

Each of `pending_products`, `default_product_quantities`, `daily_product_orders`
gets `product`, `client` and `zone` via `t.references …, null: false,
foreign_key: true` (which also creates the per-column index). Models declare
`belongs_to :product`, `belongs_to :client`, `belongs_to :zone` (Rails' default
`optional: false`). Consistent with `client-directory`'s required `Client → Zone`
link. An ordering row with a missing reference has no business meaning.

### D5. Unique index only on `DefaultProductQuantity`

`add_index :default_product_quantities, %i[product_id client_id zone_id], unique:
true`, backed by `validates :product_id, uniqueness: { scope: %i[client_id
zone_id] }` for a friendly error. A "default" is singular per combination.
`PendingProduct` and `DailyProductOrder` get no composite unique index —
repeats are legitimate (multiple pending deliveries; multiple orders logged for
a day). Confirmed with the user.

### D6. Parent-side associations use `dependent: :restrict_with_error`

`Product` (new), `Client` and `Zone` get `has_many :pending_products`,
`has_many :default_product_quantities`, `has_many :daily_product_orders`, each
`dependent: :restrict_with_error`. Deleting a referenced parent fails with a
validation error on `:base`; the database foreign key (`ON DELETE RESTRICT`, the
`foreign_key: true` default) is the second line of defence.

This implements the `product-ordering` spec's "Referential integrity on delete"
requirement directly — its scenarios assert "not deleted / still exists", which
`restrict_with_error` satisfies. It also keeps `Zone` consistent with its
existing `has_many :clients, dependent: :restrict_with_error` from
`client-directory`. `client-directory` is **not** modified: its requirement is
about clients blocking a zone deletion, and the new guards are the
`product-ordering` capability's own rule, not a change to that one.
*Alternative — no `dependent:` option, DB foreign key only:* rejected; it
surfaces as a bare `ActiveRecord::InvalidForeignKey` and trips
`Rails/HasManyOrHasOneDependent` in RuboCop.

### D7. `zone_id` is stored independently of `client.zone_id`

The three ordering models carry both `client_id` and `zone_id` even though a
client already belongs to a zone. Stored as the request specifies, with no
validation that they agree — this allows a client's zone to change without
rewriting historical rows, and lets a row be filed under a different zone
deliberately. If the business wants them locked together, that is a later
`validate` addition.

### D8. Table and file names

`products`, `pending_products`, `daily_product_orders`, and
`default_product_quantities` (Rails inflects "quantity" → "quantities"; the model
is `DefaultProductQuantity`). Models: `app/models/product.rb`,
`pending_product.rb`, `daily_product_order.rb`, `default_product_quantity.rb`.

### D9. Quantity validation differs by model

`PendingProduct#quantity` and `DailyProductOrder#quantity`:
`numericality: { only_integer: true, greater_than: 0 }` — a pending delivery or a
logged order of zero is meaningless. `DefaultProductQuantity#quantity`:
`numericality: { only_integer: true, greater_than_or_equal_to: 0 }` — a default
of `0` is meaningful ("no standing quantity"). Columns are `integer`,
`null: false`.

## Risks / Trade-offs

- `restrict_with_error` on `Client` / `Zone` for the new tables (D6) widens what
  blocks their deletion beyond clients → intended; it is the `product-ordering`
  capability's own referential-integrity rule, and the DB foreign key backs it.
- No `zone_id` / `client.zone_id` consistency check (D7) allows mismatched rows
  → intentional; add a validation if the domain requires agreement.
- `decimal(10, 2)` caps a single price at ~100M → far above expected values;
  widen the precision if that ever changes.
- Four migrations touching a shared parent (`products`) must run in order →
  handled by timestamped migration order (D-migration plan).

## Migration Plan

1. `create_products` — `name` (`string`, `null: false`, unique index),
   `price` (`decimal(10, 2)`, `null: false`), timestamps.
2. `create_pending_products` — `quantity` (`integer`, `null: false`),
   `state` (`integer`, `null: false`, `default: 0`), `product`/`client`/`zone`
   references (`null: false`, `foreign_key: true`), timestamps.
3. `create_default_product_quantities` — `product`/`client`/`zone` references
   (`null: false`, `foreign_key: true`), `quantity` (`integer`, `null: false`),
   composite unique index on `[product_id, client_id, zone_id]`, timestamps.
4. `create_daily_product_orders` — `product`/`client`/`zone` references
   (`null: false`, `foreign_key: true`), `quantity` (`integer`, `null: false`),
   `day` (`date`, `null: false`), timestamps.
5. Migration 1 runs before 2–4 (all reference `products`); 2–4 also depend on the
   existing `clients` and `zones`. Regenerate `db/schema.rb`.
6. Rollback: `bin/rails db:rollback STEP=4` drops the four tables; no data to
   preserve.

## Open Questions

None block implementation. One deferrable item, flagged above: whether `zone_id`
must match the referenced client's zone (D7). It can be added later as a
`validate` without reworking these models or specs.
