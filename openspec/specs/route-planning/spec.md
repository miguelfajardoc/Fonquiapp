# route-planning Specification

## Purpose

Route planning lets dispatch group a zone's clients into named delivery
routes and record the ordered sequence of stops (clients) each route visits,
so a driver's visiting order is explicit and can be changed later.

## Requirements

### Requirement: Route record

The system SHALL persist a route identified by a `name`. The `name` SHALL be
present (non-blank) and SHALL be unique among routes belonging to the same
zone, but the same name MAY be reused across different zones. Every route
SHALL be linked to exactly one existing zone through a required `zone_id`
reference, and the datastore SHALL enforce that referential integrity.

#### Scenario: Route created with a name and a zone

- **GIVEN** a zone exists
- **WHEN** a route is created with a non-blank `name` and that zone's `zone_id`
- **THEN** the route is persisted and reports the zone it belongs to

#### Scenario: Route rejected without a name

- **GIVEN** a zone exists
- **WHEN** a route is created with a blank or missing `name`
- **THEN** the route is not persisted
- **AND** a validation error is reported against `name`

#### Scenario: Route rejected when the name is already taken in the same zone

- **GIVEN** a zone has a route named "Ruta 1"
- **WHEN** another route is created in that same zone with the name "Ruta 1"
- **THEN** the second route is not persisted
- **AND** a uniqueness error is reported against `name`

#### Scenario: The same route name is allowed in a different zone

- **GIVEN** a zone has a route named "Ruta 1"
- **WHEN** a route named "Ruta 1" is created in a different zone
- **THEN** the route is persisted

#### Scenario: Route rejected without a zone

- **WHEN** a route is created with no `zone_id`
- **THEN** the route is not persisted
- **AND** a validation error is reported against the zone reference

#### Scenario: Route rejected when the zone does not exist

- **WHEN** a route is created with a `zone_id` that matches no zone
- **THEN** the route is not persisted because referential integrity is violated

### Requirement: Route stop record

The system SHALL persist a route stop with required references to an
existing route and an existing client, and an integer `position` locating it
within its route's sequence. Referential integrity for the route and client
references SHALL be enforced by the datastore. A given client SHALL appear
at most once within the same route, but the same client MAY appear in
different routes, and different clients MAY occupy stops in the same route.
The referenced client SHALL belong to the same zone as the referenced
route; a route stop pairing a route and a client from different zones SHALL
NOT be persisted, regardless of how it is created.

#### Scenario: Route stop created with a route and a client

- **GIVEN** a route and a client exist
- **WHEN** a route stop is created referencing that route and client
- **THEN** the route stop is persisted with a `position`

#### Scenario: Route stop rejected without a route

- **GIVEN** a client exists
- **WHEN** a route stop is created with no route
- **THEN** the route stop is not persisted
- **AND** a validation error is reported against the route reference

#### Scenario: Route stop rejected without a client

- **GIVEN** a route exists
- **WHEN** a route stop is created with no client
- **THEN** the route stop is not persisted
- **AND** a validation error is reported against the client reference

#### Scenario: Route stop rejected when the route or client does not exist

- **WHEN** a route stop is created with a `route_id` or `client_id` that matches no record
- **THEN** the route stop is not persisted because referential integrity is violated

#### Scenario: A client cannot be added twice to the same route

- **GIVEN** a route already has a stop for a client
- **WHEN** another route stop is created for the same route and the same client
- **THEN** the second route stop is not persisted
- **AND** a uniqueness error is reported

#### Scenario: The same client is allowed in different routes

- **GIVEN** a client has a stop on one route
- **WHEN** a route stop is created for that same client on a different route
- **THEN** the route stop is persisted

#### Scenario: Route stop rejected when the client belongs to a different zone than the route

- **GIVEN** a route belongs to one zone and a client belongs to a different zone
- **WHEN** a route stop is created referencing that route and that client
- **THEN** the route stop is not persisted
- **AND** a validation error is reported

#### Scenario: Route stop accepted when the client belongs to the route's zone

- **GIVEN** a route and a client that both belong to the same zone
- **WHEN** a route stop is created referencing that route and that client
- **THEN** the route stop is persisted

### Requirement: Route stop position ordering

Route stop `position` values SHALL order the stops within a route and SHALL
be scoped independently per route, so each route has its own contiguous
sequence starting at 1. A newly created route stop SHALL be placed after the
route's existing stops by default. Removing a route stop SHALL close the gap
so the remaining stops stay contiguous. Moving a stop to a new position
within its route SHALL shift the other stops of that same route to keep the
sequence contiguous, and SHALL NOT affect the positions of stops belonging to
any other route.

#### Scenario: New stops are appended in order

- **GIVEN** a route already has two stops, at positions 1 and 2
- **WHEN** a third stop is added to that route
- **THEN** the new stop is placed at position 3

#### Scenario: Removing a stop closes the gap

- **GIVEN** a route has three stops, at positions 1, 2 and 3
- **WHEN** the stop at position 2 is deleted
- **THEN** the remaining two stops occupy positions 1 and 2

#### Scenario: Moving a stop shifts the others in its route

- **GIVEN** a route has three stops, at positions 1, 2 and 3
- **WHEN** the stop at position 3 is moved to position 1
- **THEN** that stop is at position 1
- **AND** the other two stops of that route are now at positions 2 and 3

#### Scenario: Positions are independent per route

- **GIVEN** two different routes each have their own stops
- **WHEN** a stop is added to, removed from, or reordered within one route
- **THEN** the position sequence of the other route's stops is unaffected

### Requirement: Route-to-client relationship

The system SHALL let a route enumerate, in stop order, the clients reachable
through its route stops.

#### Scenario: A route lists its clients in stop order

- **GIVEN** a route has stops for client A at position 1 and client B at position 2
- **WHEN** that route's clients are listed
- **THEN** client A and client B are returned in that order

### Requirement: Referential integrity on delete

A zone that is referenced by any route SHALL NOT be deletable. A client that
is referenced by any route stop SHALL NOT be deletable. Deleting a route
SHALL delete its route stops along with it, since a route stop has no
meaning outside the route that ordered it.

#### Scenario: A referenced zone cannot be deleted

- **GIVEN** a zone referenced by a route
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is not deleted and still exists

#### Scenario: A referenced client cannot be deleted

- **GIVEN** a client referenced by a route stop
- **WHEN** deletion of that client is attempted
- **THEN** the client is not deleted and still exists

#### Scenario: Deleting a route deletes its route stops

- **GIVEN** a route with two route stops
- **WHEN** that route is deleted
- **THEN** the route and both of its route stops no longer exist

#### Scenario: An unreferenced zone can still be deleted

- **GIVEN** a zone that no route references
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is removed
