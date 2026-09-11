## Purpose

Product ordering covers the per-client, per-zone product-quantity records the
business tracks: standing defaults, day-by-day orders, and still-pending
deliveries with a small delivery lifecycle.

## ADDED Requirements

### Requirement: Pending product record

The system SHALL persist a pending product with an integer `quantity` greater
than zero, a lifecycle `state`, and required references to an existing product,
client and zone. The `state` SHALL be one of `pending`, `delivered` or
`canceled`; it SHALL default to `pending`; and the three values SHALL be
distinguishable and queryable by name. Referential integrity for the product,
client and zone references SHALL be enforced by the datastore. Several pending
products MAY exist for the same product+client+zone.

#### Scenario: Pending product created with the required data

- **GIVEN** a product, a client and a zone exist
- **WHEN** a pending product is created with `quantity` 5 and those three references
- **THEN** the pending product is persisted with `state` `pending`

#### Scenario: State moves through its lifecycle

- **GIVEN** a persisted pending product with `state` `pending`
- **WHEN** its `state` is set to `delivered` and then to `canceled`
- **THEN** each change is persisted and the record reports the new state by name

#### Scenario: Pending product rejected with a non-positive quantity

- **WHEN** a pending product is created with `quantity` 0 or a negative `quantity`
- **THEN** the pending product is not persisted
- **AND** a validation error is reported against `quantity`

#### Scenario: Pending product rejected without a product, client or zone

- **WHEN** a pending product is created with any of `product`, `client` or `zone` missing
- **THEN** the pending product is not persisted
- **AND** a validation error is reported against the missing reference

#### Scenario: Pending product rejected when a reference points nowhere

- **WHEN** a pending product is created with a `product_id`, `client_id` or `zone_id` that matches no record
- **THEN** the pending product is not persisted because referential integrity is violated

#### Scenario: Repeated pending products for one combination are allowed

- **GIVEN** a pending product for a product+client+zone already exists
- **WHEN** another pending product is created for the same product+client+zone
- **THEN** both pending products are persisted

### Requirement: Default product quantity record

The system SHALL persist a default product quantity with required references to
an existing product, client and zone, and an integer `quantity` of zero or more.
There SHALL be at most one default product quantity per product+client+zone
combination. Referential integrity for the three references SHALL be enforced by
the datastore.

#### Scenario: Default quantity created for a combination

- **GIVEN** a product, a client and a zone exist
- **WHEN** a default product quantity is created with `quantity` 10 and those references
- **THEN** the record is persisted

#### Scenario: A quantity of zero is allowed

- **WHEN** a default product quantity is created with `quantity` 0
- **THEN** the record is persisted

#### Scenario: Default quantity rejected with a negative or non-integer quantity

- **WHEN** a default product quantity is created with a negative or non-integer `quantity`
- **THEN** the record is not persisted
- **AND** a validation error is reported against `quantity`

#### Scenario: Only one default per product+client+zone

- **GIVEN** a default product quantity exists for a product+client+zone
- **WHEN** another default product quantity is created for the same product+client+zone
- **THEN** the second record is not persisted
- **AND** a uniqueness error is reported

#### Scenario: A different combination keeps its own default

- **GIVEN** a default product quantity exists for one product+client+zone
- **WHEN** a default product quantity is created for a combination that differs in any of product, client or zone
- **THEN** that record is persisted

#### Scenario: Default quantity rejected without a product, client or zone

- **WHEN** a default product quantity is created with any of `product`, `client` or `zone` missing
- **THEN** the record is not persisted
- **AND** a validation error is reported against the missing reference

### Requirement: Daily product order record

The system SHALL persist a daily product order with required references to an
existing product, client and zone, an integer `quantity` greater than zero, and
a `day` that is a calendar date (no time component). Referential integrity for
the three references SHALL be enforced by the datastore. Several daily product
orders MAY exist for the same product+client+zone on the same day.

#### Scenario: Daily order created with the required data

- **GIVEN** a product, a client and a zone exist
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

#### Scenario: Repeated daily orders for one combination and day are allowed

- **GIVEN** a daily product order for a product+client+zone on `2026-09-10` exists
- **WHEN** another daily product order is created for the same product+client+zone on `2026-09-10`
- **THEN** both records are persisted

### Requirement: Referential integrity on delete

A product, client or zone that is referenced by any pending product, default
product quantity or daily product order SHALL NOT be deletable, so no ordering
record is ever left pointing at a missing product, client or zone.

#### Scenario: A referenced product cannot be deleted

- **GIVEN** a product referenced by a daily product order
- **WHEN** deletion of that product is attempted
- **THEN** the product is not deleted and still exists

#### Scenario: A referenced client cannot be deleted

- **GIVEN** a client referenced by a default product quantity
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
