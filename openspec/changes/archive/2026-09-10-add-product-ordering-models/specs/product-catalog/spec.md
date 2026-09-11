## Purpose

The product catalogue is the ERP's master list of the items the business
delivers to clients — each item's name and its price — kept well-formed so the
ordering records can refer to it reliably.

## ADDED Requirements

### Requirement: Product identity

The system SHALL persist a product identified by a name. The name SHALL be
present (non-blank) and SHALL be unique across all products, so a product can be
referred to unambiguously.

#### Scenario: Product created with a name

- **WHEN** a product is created with a non-blank `name` and a valid price
- **THEN** the product is persisted and can be retrieved by that name

#### Scenario: Product rejected without a name

- **WHEN** a product is created with a blank or missing `name`
- **THEN** the product is not persisted
- **AND** a validation error is reported against `name`

#### Scenario: Product rejected when the name is already taken

- **GIVEN** a product named "Agua 500ml" already exists
- **WHEN** another product is created with the name "Agua 500ml"
- **THEN** the second product is not persisted
- **AND** a uniqueness error is reported against `name`

### Requirement: Product price

The system SHALL store a product price as a required, fixed-scale decimal amount
with two decimal places. The price SHALL NOT be negative. A value supplied with
more than two decimal places SHALL be recorded rounded to two.

#### Scenario: Price kept at two decimal places

- **WHEN** a product is created with a price of `12.5`
- **THEN** the product is persisted
- **AND** the stored price reads back as `12.50`

#### Scenario: Product rejected without a price

- **WHEN** a product is created with no price
- **THEN** the product is not persisted
- **AND** a validation error is reported against `price`

#### Scenario: Product rejected with a negative price

- **WHEN** a product is created with a price of `-1.00`
- **THEN** the product is not persisted
- **AND** a validation error is reported against `price`
