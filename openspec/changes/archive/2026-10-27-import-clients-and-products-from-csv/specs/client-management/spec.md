## MODIFIED Requirements

### Requirement: Client creation

The system SHALL let a user submit a name, optional address and phone, an
optional map location (placed with the location picker), and a required
zone to create a new client. The form SHALL NOT offer a url field; the url
is derived from the location. The system SHALL keep the user on the creation
form with the invalid input and an error when the name or zone is missing
or the name is already used by another client (ignoring letter case and
accents), and SHALL let the user cancel back to the client index without creating a
client.

#### Scenario: Creating a client with a name and a zone

- **GIVEN** a zone exists
- **WHEN** the new-client form is submitted with a non-blank name and that
  zone selected
- **THEN** the client is created
- **AND** the user is shown the new client

#### Scenario: Creating a client with a map location

- **GIVEN** a zone exists
- **WHEN** the new-client form is submitted with a name, that zone, and a pin
  at latitude 4.711 and longitude -74.0721
- **THEN** the client is created with those coordinates
- **AND** its url is a Google Maps link to those coordinates

#### Scenario: The form has no url field

- **WHEN** the new-client form is opened
- **THEN** no url field is offered

#### Scenario: Creating a client without a name or without a zone

- **WHEN** the new-client form is submitted with a blank name, or with no
  zone selected
- **THEN** no client is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Creating a client with a name already in use

- **GIVEN** a client named "Tienda San José" exists
- **WHEN** the new-client form is submitted with the name "TIENDA SAN JOSE"
  and a zone selected
- **THEN** no client is created
- **AND** the creation form is shown again with an error saying the name is
  already in use

#### Scenario: Canceling client creation

- **WHEN** cancel is chosen on the new-client form
- **THEN** the user is returned to the client index
- **AND** no client is created

### Requirement: Client editing

The system SHALL let a user update a client's name, address, phone, map
location, and zone. The form SHALL NOT offer a url field; the url is
re-derived from the location on every save. The system SHALL keep the user
on the edit form with the invalid input and an error when the name or zone
is cleared or the name is changed to one already used by another client
(ignoring letter case and accents), and SHALL let the user cancel back
without changing the client.

#### Scenario: Updating a client with valid data

- **GIVEN** a client exists
- **WHEN** that client's edit form is submitted with a non-blank name and a
  zone selected
- **THEN** the client's data is updated

#### Scenario: Updating a client's map location

- **GIVEN** a client exists with no coordinates
- **WHEN** that client's edit form is submitted with a pin at latitude 4.65
  and longitude -74.1
- **THEN** the client's coordinates are updated
- **AND** its url is a Google Maps link to those coordinates

#### Scenario: Updating a client with a blank name or no zone

- **GIVEN** a client exists
- **WHEN** that client's edit form is submitted with a blank name, or with
  no zone selected
- **THEN** the client is not changed
- **AND** the edit form is shown again with a validation error

#### Scenario: Renaming a client to a name already in use

- **GIVEN** clients named "Tienda Norte" and "Tienda Sur" exist
- **WHEN** the edit form of "Tienda Sur" is submitted with the name
  "tienda norte"
- **THEN** the client is not changed
- **AND** the edit form is shown again with an error saying the name is
  already in use

#### Scenario: Canceling client editing

- **GIVEN** a client exists
- **WHEN** cancel is chosen on that client's edit form
- **THEN** the client is not changed
