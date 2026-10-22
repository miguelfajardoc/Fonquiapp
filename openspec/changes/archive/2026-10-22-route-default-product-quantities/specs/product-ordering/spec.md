## MODIFIED Requirements

### Requirement: Referential integrity on delete

A product that is referenced by any pending product, default product quantity
or daily product order SHALL NOT be deletable. A client that is referenced by
any pending product SHALL NOT be deletable. A zone that is referenced by any
pending product or daily product order SHALL NOT be deletable. No ordering
record SHALL ever be left pointing at a missing product, client or zone.

#### Scenario: A referenced product cannot be deleted

- **GIVEN** a product referenced by a daily product order
- **WHEN** deletion of that product is attempted
- **THEN** the product is not deleted and still exists

#### Scenario: A product referenced by a default quantity cannot be deleted

- **GIVEN** a product referenced by a default product quantity
- **WHEN** deletion of that product is attempted
- **THEN** the product is not deleted and still exists

#### Scenario: A referenced client cannot be deleted

- **GIVEN** a client referenced by a pending product
- **WHEN** deletion of that client is attempted
- **THEN** the client is not deleted and still exists

#### Scenario: A referenced zone cannot be deleted

- **GIVEN** a zone referenced by a pending product
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is not deleted and still exists

#### Scenario: An unreferenced product can still be deleted

- **GIVEN** a product that no pending product, default product quantity or daily product order references
- **WHEN** deletion of that product is attempted
- **THEN** the product is removed

## ADDED Requirements

### Requirement: Route default product quantity record

The system SHALL persist a default product quantity with required references to
an existing route and an existing product, and an integer `quantity` greater
than zero. A default product quantity SHALL NOT reference a client or a zone;
its zone is the zone of its route. There SHALL be at most one default product
quantity per route+product combination. Referential integrity for the two
references SHALL be enforced by the datastore.

#### Scenario: Default quantity created for a route and product

- **GIVEN** a route and a product exist
- **WHEN** a default product quantity is created with `quantity` 10 and those references
- **THEN** the record is persisted

#### Scenario: Default quantity rejected with a zero, negative or non-integer quantity

- **WHEN** a default product quantity is created with `quantity` 0, a negative `quantity`, or a non-integer `quantity`
- **THEN** the record is not persisted
- **AND** a validation error is reported against `quantity`

#### Scenario: Only one default per route+product

- **GIVEN** a default product quantity exists for a route+product
- **WHEN** another default product quantity is created for the same route+product
- **THEN** the second record is not persisted
- **AND** a uniqueness error is reported

#### Scenario: A different combination keeps its own default

- **GIVEN** a default product quantity exists for one route+product
- **WHEN** a default product quantity is created for a combination that differs in route or in product
- **THEN** that record is persisted

#### Scenario: Default quantity rejected without a route or product

- **WHEN** a default product quantity is created with `route` or `product` missing
- **THEN** the record is not persisted
- **AND** a validation error is reported against the missing reference

### Requirement: Route daily product order record

The system SHALL persist a daily product order with required references to an
existing product, zone, and route, an integer `quantity` greater than zero,
and a `day` that is a calendar date (no time component). A daily product order
SHALL NOT reference a client. Referential integrity for the three references
SHALL be enforced by the datastore. Several daily product orders MAY exist for
the same product+route on the same day.

#### Scenario: Daily order created with the required data

- **GIVEN** a product, a zone, and a route exist
- **WHEN** a daily product order is created with `quantity` 3, a `day` of `2026-09-10`, and those references
- **THEN** the record is persisted and `day` reads back as the date `2026-09-10`

#### Scenario: Daily order rejected without a day

- **WHEN** a daily product order is created with no `day`
- **THEN** the record is not persisted
- **AND** a validation error is reported against `day`

#### Scenario: Daily order rejected with a non-positive or non-integer quantity

- **WHEN** a daily product order is created with `quantity` 0, a negative `quantity`, or a non-integer `quantity`
- **THEN** the record is not persisted
- **AND** a validation error is reported against `quantity`

#### Scenario: Daily order rejected without a product or zone

- **WHEN** a daily product order is created with `product` or `zone` missing
- **THEN** the record is not persisted
- **AND** a validation error is reported against the missing reference

#### Scenario: Daily order rejected without a route

- **WHEN** a daily product order is created with no `route`
- **THEN** the record is not persisted
- **AND** a validation error is reported against the route reference

#### Scenario: Daily order rejected when the route does not exist

- **WHEN** a daily product order is created with a `route_id` that matches no route
- **THEN** the record is not persisted because referential integrity is violated

#### Scenario: Repeated daily orders for one combination and day are allowed

- **GIVEN** a daily product order for a product+route on `2026-09-10` exists
- **WHEN** another daily product order is created for the same product+route on `2026-09-10`
- **THEN** both records are persisted

## REMOVED Requirements

### Requirement: Default product quantity record

**Reason**: Default quantities now belong to a route and a product instead of a product+client+zone, and must be greater than zero.
**Migration**: See "Route default product quantity record".

### Requirement: Daily product order record

**Reason**: Daily orders no longer reference a client; a route's batch has one order per product.
**Migration**: See "Route daily product order record".
