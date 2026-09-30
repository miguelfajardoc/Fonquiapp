## Context

See proposal.md - Why. This app is a Rails 8 ERP using PostgreSQL, RSpec +
FactoryBot for tests, and a consistent existing pattern for "reference"
models: a `belongs_to` for each foreign key, `has_many ... dependent:
:restrict_with_error` on the referenced side, a presence/uniqueness
validation backed by a matching database unique index, and a factory +
model spec per model (see `default_product_quantity.rb`/spec/factory as the
closest existing analog: three required references plus a scoped uniqueness
constraint).

This change introduces the first ordered list in the app (route stops), so
it also introduces the `acts_as_list` gem, which is not yet a dependency.

## Goals / Non-Goals

**Goals:**
- Persist `Route` (per zone) and `RouteStop` (ordered, per route) records
  that satisfy `specs/route-planning/spec.md`.
- Keep stop ordering correct and automatic using `acts_as_list`, scoped per
  route, matching the project's established model conventions.
- Provide seeds and model specs/factories so the new models are exercised
  the same way every other model in this app is.

**Non-Goals:**
- No controllers, views, routes.rb entries, or any web UI for routes/stops
  (matches how `product-ordering` and `client-directory` shipped their
  models before any CRUD UI existed for them).
- No changes to how existing models (`Zone`, `Client`) behave for callers
  other than gaining a new association; their existing validations and
  UI-facing behavior (`zone-management`, `client-directory`) are unchanged.

## Decisions

### Schema

```ruby
create_table :routes do |t|
  t.string  :name, null: false
  t.references :zone, null: false, foreign_key: true
  t.timestamps
end
add_index :routes, [:zone_id, :name], unique: true

create_table :route_stops do |t|
  t.references :route, null: false, foreign_key: true
  t.references :client, null: false, foreign_key: true
  t.integer :position
  t.timestamps
end
add_index :route_stops, [:route_id, :client_id], unique: true
add_index :route_stops, [:route_id, :position]
```

`position` is nullable at the database level because `acts_as_list` assigns
it itself in a `before_create` callback; the app never leaves it unset once
a record is persisted. Every other model in this app backs its uniqueness
validation with a matching unique index (see `default_product_quantities`'
composite index); the same is done here for both new uniqueness rules.

### Models

```ruby
class Route < ApplicationRecord
  belongs_to :zone

  has_many :route_stops, dependent: :destroy
  has_many :clients, through: :route_stops

  validates :name, presence: true, uniqueness: { scope: :zone_id }
end
```

```ruby
class RouteStop < ApplicationRecord
  belongs_to :route
  belongs_to :client

  acts_as_list scope: :route

  validates :client_id, uniqueness: { scope: :route_id }
end
```

`Zone` gains `has_many :routes, dependent: :restrict_with_error` and
`Client` gains `has_many :route_stops, dependent: :restrict_with_error`,
alongside their existing `has_many` lines, matching those models' existing
restrict-on-delete pattern for every other reference table.

**Why `dependent: :destroy` on `Route -> route_stops` but
`:restrict_with_error` everywhere else in this app**: every other
restricted association in this app (pending products, default quantities,
daily orders) is an independent business record that must not silently
disappear. A route stop has no identity or meaning outside the route that
ordered it - it is the route's own list content, not a record another part
of the system points at - so cascading delete is correct here, and this was
confirmed with the user rather than assumed. `Client -> route_stops` stays
`:restrict_with_error` because a client is independent of any one route,
consistent with how `Client` already guards its other associations.

**Why uniqueness of `Route#name` is scoped to `zone_id` instead of global**:
per the user, `name` is a per-zone label/number (e.g. "Ruta 1"), and
different zones may reasonably reuse the same route name, unlike
`Zone#name` or `Product#name`, which are global identifiers.

**Why `acts_as_list scope: :route` instead of `scope: :route_id`**: both are
equivalent - `acts_as_list` treats a scope symbol not ending in `_id` as
shorthand for the matching foreign-key column. `:route` is what the user
specified and reads more clearly next to a `belongs_to :route`.

**Alternative considered**: enforcing per-route client uniqueness only at
the model-validation level, without a matching unique index. Rejected
because every other uniqueness rule in this app is backed by a database
index (defends against races and matches `default_product_quantities`).

### Gem

Add `gem "acts_as_list"` to the main (non-grouped) section of the `Gemfile`,
next to the other runtime gems, since it is used by application code, not
just tests.

### Seeds

Routes are created with `find_or_create_by!(zone:, name:)`, like `Zone` and
`Product`, so re-running seeds doesn't duplicate them. Route stops are
regenerated every run (`RouteStop.delete_all` then recreate), like
`DefaultProductQuantity` and `PendingProduct`, since they are illustrative
sample data rather than stable reference data: for each zone, create one or
two routes and add that zone's clients as stops in a shuffled order,
relying on `acts_as_list` to assign positions.

### Tests

- `spec/factories/routes.rb`: `association :zone`, sequenced `name`.
- `spec/factories/route_stops.rb`: `association :route`, `association
  :client`.
- `spec/models/route_spec.rb`: name presence/uniqueness-per-zone, zone
  presence and referential integrity, `clients` through `route_stops` (in
  position order), cascading delete of route stops.
- `spec/models/route_stop_spec.rb`: route/client presence and referential
  integrity, per-route client uniqueness, and `acts_as_list` ordering
  behavior (append on create, gap-closing on destroy, reordering with
  `insert_at`, independence between two routes' position sequences) -
  covering every scenario in `specs/route-planning/spec.md`.

## Risks / Trade-offs

- [`acts_as_list` renumbers remaining rows with individual `UPDATE`
  statements when a stop is destroyed or moved] → acceptable: route stop
  counts per route are small (tens, not thousands), so this is not a
  performance concern at this app's scale.
- [Introducing a new gem adds a small maintenance/upgrade surface] →
  `acts_as_list` is a long-established, widely used gem for exactly this
  need; no lighter-weight in-house alternative was considered worth
  building.
