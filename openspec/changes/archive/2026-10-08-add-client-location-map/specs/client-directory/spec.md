## MODIFIED Requirements

### Requirement: Client record

The system SHALL persist a client as a record with a name and optional
contact details. The name SHALL be present (non-blank). The fields
`address` and `phone` SHALL each be optional free text. The client SHALL
also have an optional location made of `latitude` and `longitude`, and a
`url` that the system derives from that location and the address (it is not
free text). Every client SHALL be linked to exactly one existing zone through
a required `zone_id` reference, and the datastore SHALL enforce that
referential integrity.

#### Scenario: Client created with a name and a zone

- **GIVEN** a zone exists
- **WHEN** a client is created with a non-blank `name` and that zone's `zone_id`
- **THEN** the client is persisted and reports the zone it belongs to

#### Scenario: Client rejected without a name

- **WHEN** a client is created with a blank or missing `name`
- **THEN** the client is not persisted
- **AND** a validation error is reported against `name`

#### Scenario: Client rejected without a zone

- **WHEN** a client is created with no `zone_id`
- **THEN** the client is not persisted
- **AND** a validation error is reported against the zone reference

#### Scenario: Contact details are optional

- **GIVEN** a zone exists
- **WHEN** a client is created with a `name` and a zone but no `address`,
  `phone`, `latitude` or `longitude`
- **THEN** the client is persisted, the omitted fields are empty, and its
  `url` is empty

#### Scenario: Client rejected when the zone does not exist

- **WHEN** a client is created with a `zone_id` that matches no zone
- **THEN** the client is not persisted because referential integrity is violated
