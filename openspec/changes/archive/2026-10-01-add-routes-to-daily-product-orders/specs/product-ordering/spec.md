## MODIFIED Requirements

### Requirement: Daily product order record

The system SHALL persist a daily product order with required references to an
existing product, client, zone, and route, an integer `quantity` greater than
zero, and a `day` that is a calendar date (no time component). Referential
integrity for the four references SHALL be enforced by the datastore. Several
daily product orders MAY exist for the same product+client+zone on the same
day.

#### Scenario: Daily order created with the required data

- **GIVEN** a product, a client, a zone, and a route exist
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

#### Scenario: Daily order rejected without a product, client or zone

- **WHEN** a daily product order is created with any of `product`, `client` or `zone` missing
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

- **GIVEN** a daily product order for a product+client+zone on `2026-09-10` exists
- **WHEN** another daily product order is created for the same product+client+zone on `2026-09-10`
- **THEN** both records are persisted
