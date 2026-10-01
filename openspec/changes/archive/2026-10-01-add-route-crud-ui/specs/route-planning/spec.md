## MODIFIED Requirements

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
