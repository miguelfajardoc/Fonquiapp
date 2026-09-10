## Why

The ERP has no domain models yet. The first thing the business needs recorded is
*who its clients are* and *which geographic zone each client belongs to*, so that
later work (assignment, routing, reporting) has stable entities to build on. This
change introduces those two records — `Zone` and `Client` — and nothing else.

## What Changes

- Add a **`Zone`** model backed by a `zones` table with a `name` string.
- Add a **`Client`** model backed by a `clients` table with `name`, `address`,
  `url` and `phone` strings, plus a `zone_id` reference to `Zone`.
- Add the association: `Client belongs_to :zone` and `Zone has_many :clients`.
- Add the two migrations, a foreign-key constraint on `clients.zone_id` and an
  index on that column.
- Add model-level validations (see the spec for the exact rules).
- Add a FactoryBot factory and a model spec for each model, per the project's
  RSpec convention. Nothing else.
- **Out of scope:** controllers, routes, views, JSON/serializers, jobs, seeds,
  policies, admin screens. Models + migrations + specs only.

## Capabilities

### New Capabilities
- `client-directory`: the master list of clients and the zones used to group
  them — the two records, the zone↔client relationship, and the data-integrity
  rules that keep those records well-formed.

### Modified Capabilities
<!-- none: this is the first domain capability in the project -->

## Impact

- **New code:** `app/models/zone.rb`, `app/models/client.rb`, two files under
  `db/migrate/`, regenerated `db/schema.rb`.
- **New tests:** `spec/models/zone_spec.rb`, `spec/models/client_spec.rb`,
  `spec/factories/zones.rb`, `spec/factories/clients.rb`.
- **Database:** two new tables, one foreign-key constraint, one index. No data
  migration or backfill.
- **No** changes to routing, HTTP, dependencies, or configuration.
