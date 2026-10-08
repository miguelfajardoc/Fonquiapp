## MODIFIED Requirements

### Requirement: Client detail view

The system SHALL display a client's name, address, url, phone, and zone on
its detail view, along with a control to edit and a control to delete that
client. Beside that data the detail view SHALL show the client's embedded
location map, as defined by the client-location capability.

#### Scenario: Detail view shows every field and both actions

- **GIVEN** a client exists
- **WHEN** that client's detail view is shown
- **THEN** its name, address, url, phone, and zone are displayed
- **AND** an edit control and a delete control are displayed

#### Scenario: Detail view shows the location map

- **GIVEN** a client with saved coordinates exists and a Google Maps API key
  is configured
- **WHEN** that client's detail view is shown
- **THEN** an embedded map of the client's location is displayed beside its
  data

### Requirement: Client creation

The system SHALL let a user submit a name, optional address and phone, an
optional map location (placed with the location picker), and a required
zone to create a new client. The form SHALL NOT offer a url field; the url
is derived from the location. The system SHALL keep the user on the creation
form with the invalid input and an error when the name or zone is missing,
and SHALL let the user cancel back to the client index without creating a
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

#### Scenario: Canceling client creation

- **WHEN** cancel is chosen on the new-client form
- **THEN** the user is returned to the client index
- **AND** no client is created

### Requirement: Client editing

The system SHALL let a user update a client's name, address, phone, map
location, and zone. The form SHALL NOT offer a url field; the url is
re-derived from the location on every save. The system SHALL keep the user
on the edit form with the invalid input and an error when the name or zone
is cleared, and SHALL let the user cancel back without changing the client.

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

#### Scenario: Canceling client editing

- **GIVEN** a client exists
- **WHEN** cancel is chosen on that client's edit form
- **THEN** the client is not changed
