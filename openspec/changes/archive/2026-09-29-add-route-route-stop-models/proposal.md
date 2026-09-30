## Why

Delivery zones currently group clients but have no way to organize them into
an ordered delivery sequence. Dispatch needs to define named routes within a
zone and list, in order, which clients each route visits, so a driver's stop
order can be recorded and later reordered as needs change.

## What Changes

- Add a `Route` model: belongs to a `Zone`, has a `name` (text label, unique
  within its zone), and has many clients through its route stops.
- Add a `RouteStop` model: belongs to a `Route` and a `Client`, with an
  integer `position` that orders the stops within a route. A given client can
  appear at most once per route. Deleting a route deletes its route stops.
- Add the `acts_as_list` gem and use it on `RouteStop` (`acts_as_list scope:
  :route`) so stop positions are automatically maintained per route (no gaps,
  automatic renumbering on insert/remove/reorder).
- Seed a handful of routes per zone with an ordered list of that zone's
  clients as route stops.
- Add model specs (validations, associations, ordering behavior, referential
  integrity) and factories for both models.

No web UI, controllers, or routes are added in this change — it introduces
the data model only, matching how `product-ordering` and `client-directory`
introduced their record types before any CRUD UI existed for them.

## Capabilities

### New Capabilities
- `route-planning`: persistence, validation, ordering, and referential
  integrity rules for `Route` and `RouteStop` records.

### Modified Capabilities
(none — this change only adds new record types; no existing capability's
requirements change)

## Impact

- **Code**: new `app/models/route.rb`, `app/models/route_stop.rb`; migration
  adding `routes` and `route_stops` tables; `Zone` gains a `has_many :routes`
  association (implementation detail, not a change to zone-management's
  documented behavior).
- **Dependencies**: adds the `acts_as_list` gem to the `Gemfile`.
- **Data**: `db/seeds.rb` gains route + route stop seeding.
- **Tests**: new `spec/models/route_spec.rb`, `spec/models/route_stop_spec.rb`,
  `spec/factories/routes.rb`, `spec/factories/route_stops.rb`.
