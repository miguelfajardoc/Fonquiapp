## Context

Fresh Rails 8.1 app on PostgreSQL, with RSpec and FactoryBot already wired up.
There are no domain models or migrations yet — `Zone` and `Client` are the
first. Project convention (openspec/project.md): business logic lives in models
or `app/services`, RESTful names, run `bin/rubocop -A` before committing. See
proposal.md — Why for motivation. See the `client-directory` spec for the
behavior contract.

## Goals / Non-Goals

**Goals:**

- Two persisted records with integrity enforced at both the database and the
  model layer.
- A `Zone` ⟷ `Client` relationship whose referential integrity is guaranteed by
  a database foreign key, not only by application code.
- Factories and model specs that exercise every scenario in the spec.

**Non-Goals:**

- No CRUD surface, seeds, serialization, or admin screens (proposal — Out of
  scope).
- No soft-delete, audit trail, versioning, or tenant scoping.
- No format validation on `url` or `phone` — presence rules from the spec only.

## Decisions

### D1. Rails-conventional names: `Client` (singular) and `zone_id`

The request said `Clients` and `id_zone`; both are renamed to what Rails infers
by default. This keeps `belongs_to :zone` / `has_many :clients`, the generators,
and table-name inference working with zero overrides.
*Alternative — keep the literal names:* rejected; it needs `self.table_name` and
explicit `class_name:` / `foreign_key:` on every association, forever.

### D2. `zone` is required on `Client`

`belongs_to :zone` (Rails' default is `optional: false`), plus `null: false` on
`clients.zone_id` and a foreign-key constraint. A client with no zone carries no
meaning for the grouping use case in the proposal.
*Alternative — optional zone:* a small change (`optional: true`, drop
`null: false`) if the business later needs unassigned clients. Flagged for the
user to decide at apply time.

### D3. Zone deletion is restricted while clients reference it

`has_many :clients, dependent: :restrict_with_error`, and the foreign key keeps
its default `on_delete: :restrict`.
*Alternatives:* `dependent: :destroy` (rejected — silently destroys client master
data); `dependent: :nullify` (rejected — requires an optional zone, contradicts
D2).

### D4. `Zone#name` unique, `Client#name` not

Zones are a small controlled list, so a unique index plus a uniqueness
validation stops duplicates that would make grouping ambiguous. Clients may
legitimately share a name (franchises, common business names), so only presence
is enforced. Uniqueness is case-sensitive; a case-insensitive rule would be a
`lower(name)` functional index — noted, not done.

### D5. Column types and constraints

All requested attributes are `string` (Postgres `varchar`, no explicit limit);
`zone_id` is `bigint`. `NOT NULL` on `zones.name`, `clients.name`,
`clients.zone_id`; `address`, `url`, `phone` are nullable. `add_reference
:clients, :zone` creates the index on `clients.zone_id` that backs both
`zone.clients` and the foreign key.

## Risks / Trade-offs

- Required zone (D2) blocks importing legacy clients that predate zones →
  mitigation: switch to `optional: true` and backfill later; one spec scenario
  would change.
- `restrict_with_error` (D3) means a populated zone can't be deleted until its
  clients are reassigned → acceptable for master data; a future admin flow can
  handle reassignment.
- Case-sensitive zone uniqueness (D4) permits "Norte" and "norte" to coexist →
  low impact at this scale; revisit with a functional index if needed.

## Migration Plan

1. Migration one creates `zones` (`name`, `NOT NULL`, unique index, timestamps).
2. Migration two creates `clients` (`name` `NOT NULL`, `address`, `url`,
   `phone`, `add_reference :clients, :zone, null: false, foreign_key: true`,
   timestamps). Must run after `zones` exists.
3. Regenerate and commit `db/schema.rb`.
4. Rollback: `bin/rails db:rollback STEP=2` drops both tables; no data to
   preserve.

## Open Questions

None block implementation. The two reversible choices — optional vs. required
zone (D2) and case-sensitivity of zone-name uniqueness (D4) — are called out for
the user to confirm or override when applying.
