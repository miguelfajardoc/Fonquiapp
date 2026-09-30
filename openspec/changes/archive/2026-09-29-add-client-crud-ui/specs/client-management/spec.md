## Purpose

The client management flow is the web interface staff use to list, view,
create, edit, and remove clients, without needing console or database
access, while respecting the client's existing validation and
delete-restriction rules and letting a zone be created on the spot instead of
interrupting client entry.

## ADDED Requirements

### Requirement: Client management routes

The system SHALL expose web routes to list clients, view a single client's
detail, start and submit client creation, start and submit client editing,
and delete a client.

#### Scenario: Every action is reachable

- **WHEN** a request is made to list clients, to view a client's detail, to
  the new-client form, to create a client, to the edit-client form, to
  update a client, or to delete a client
- **THEN** the corresponding action handles the request

### Requirement: Client index listing

The system SHALL display, for every client, its name, address, url, phone,
and zone name, alongside a control to delete that client, and SHALL display
a control to start creating a new client. Selecting a client elsewhere on
its row SHALL open that client's detail view.

#### Scenario: Index lists all clients with their fields and a delete control

- **GIVEN** at least one client exists
- **WHEN** the client index is viewed
- **THEN** every existing client's name, address, url, phone, and zone name
  are displayed
- **AND** each client has a delete control

#### Scenario: Index offers a way to create a client

- **WHEN** the client index is viewed
- **THEN** a control to start creating a new client is displayed

#### Scenario: Selecting a client row opens its detail view

- **GIVEN** a client exists
- **WHEN** that client's row is selected on the index (other than its delete
  control)
- **THEN** that client's detail view is shown

### Requirement: Client detail view

The system SHALL display a client's name, address, url, phone, and zone on
its detail view, along with a control to edit and a control to delete that
client.

#### Scenario: Detail view shows every field and both actions

- **GIVEN** a client exists
- **WHEN** that client's detail view is shown
- **THEN** its name, address, url, phone, and zone are displayed
- **AND** an edit control and a delete control are displayed

### Requirement: Client creation

The system SHALL let a user submit a name, optional address/url/phone, and a
required zone to create a new client, SHALL keep the user on the creation
form with the invalid input and an error when the name or zone is missing,
and SHALL let the user cancel back to the client index without creating a
client.

#### Scenario: Creating a client with a name and a zone

- **GIVEN** a zone exists
- **WHEN** the new-client form is submitted with a non-blank name and that
  zone selected
- **THEN** the client is created
- **AND** the user is shown the new client

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

The system SHALL let a user update a client's name, address, url, phone, and
zone, SHALL keep the user on the edit form with the invalid input and an
error when the name or zone is cleared, and SHALL let the user cancel back
without changing the client.

#### Scenario: Updating a client with valid data

- **GIVEN** a client exists
- **WHEN** that client's edit form is submitted with a non-blank name and a
  zone selected
- **THEN** the client's data is updated

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

### Requirement: Client deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with a
cancel option and a confirm option, before deleting a client. The system
SHALL NOT delete the client unless the confirm option is chosen. When the
confirm option is chosen for a client that cannot be deleted because it is
still referenced by other records, the system SHALL leave the client in
place and SHALL report that the deletion could not be completed.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a client exists
- **WHEN** the delete control is chosen for that client
- **THEN** a confirmation prompt is shown with a cancel option and a confirm
  option
- **AND** the client still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the client

- **GIVEN** a client exists and its delete confirmation prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the client still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion of an unreferenced client

- **GIVEN** a client exists with no ordering records referencing it
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the client is deleted

#### Scenario: Confirming deletion of a client still in use

- **GIVEN** a client exists that is referenced by at least one ordering
  record
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the client is not deleted
- **AND** the system reports that the client could not be deleted

### Requirement: Creating a zone inline from the client form

The system SHALL let a user create a new zone from within the client
creation or editing form, without losing the in-progress client form, by
opening a prompt that accepts a zone name. Successfully creating a zone this
way SHALL close that prompt and select the new zone in the client form's
zone field. Submitting the prompt with a blank or already-taken zone name
SHALL keep the prompt open and report the validation error, and SHALL NOT
change the client form's current zone selection.

#### Scenario: Creating a zone from the client form selects it

- **GIVEN** the client creation or editing form is open
- **WHEN** the inline zone-creation prompt is submitted with a non-blank,
  unused zone name
- **THEN** the zone is created
- **AND** that zone is selected in the client form's zone field
- **AND** the rest of the client form's entered data is unchanged

#### Scenario: Invalid zone name keeps the prompt open

- **GIVEN** the client creation or editing form is open and a zone named
  "Norte" already exists
- **WHEN** the inline zone-creation prompt is submitted with a blank name,
  or with "Norte"
- **THEN** no zone is created
- **AND** the prompt is shown again with a validation error
- **AND** the client form's current zone selection is unchanged
