# client-directory Specification

## Purpose
The client directory is the ERP's master list of the clients the business
serves, together with the geographic zones used to group them and the
integrity rules that keep both records well-formed.

## Requirements

### Requirement: Zone record

The system SHALL persist a zone as a record identified by a name. The name
SHALL be present (non-blank) and SHALL be unique across all zones, so a zone
can be referred to unambiguously.

#### Scenario: Zone created with a name

- **WHEN** a zone is created with a non-blank `name`
- **THEN** the zone is persisted and can be retrieved by that name

#### Scenario: Zone rejected without a name

- **WHEN** a zone is created with a blank or missing `name`
- **THEN** the zone is not persisted
- **AND** a validation error is reported against `name`

#### Scenario: Zone rejected when the name is already taken

- **GIVEN** a zone named "Norte" already exists
- **WHEN** another zone is created with the name "Norte"
- **THEN** the second zone is not persisted
- **AND** a uniqueness error is reported against `name`

### Requirement: Client record

The system SHALL persist a client as a record with a name and optional
contact details. The name SHALL be present (non-blank). The fields
`address`, `url` and `phone` SHALL each be optional free text. Every client
SHALL be linked to exactly one existing zone through a required `zone_id`
reference, and the datastore SHALL enforce that referential integrity.

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
- **WHEN** a client is created with a `name` and a zone but no `address`, `url` or `phone`
- **THEN** the client is persisted and the omitted fields are empty

#### Scenario: Client rejected when the zone does not exist

- **WHEN** a client is created with a `zone_id` that matches no zone
- **THEN** the client is not persisted because referential integrity is violated

### Requirement: Zone-to-client relationship

The system SHALL let a zone enumerate the clients that reference it. A zone
that still has at least one client SHALL NOT be deletable, so that no client
is left pointing at a missing zone.

#### Scenario: A zone lists its clients

- **GIVEN** a zone with two clients referencing it and one client referencing a different zone
- **WHEN** that zone's clients are listed
- **THEN** exactly the two clients that reference it are returned

#### Scenario: Deleting a zone that still has clients is blocked

- **GIVEN** a zone with at least one client
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is not deleted
- **AND** the zone and its clients still exist

#### Scenario: Deleting a zone with no clients succeeds

- **GIVEN** a zone with no clients
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is removed
