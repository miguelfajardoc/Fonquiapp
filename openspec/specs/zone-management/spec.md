# zone-management Specification

## Purpose

The zone management flow is the web interface staff use to list, create,
edit, and remove zones, without needing console or database access, while
respecting the zone's existing validation and delete-restriction rules.

## Requirements

### Requirement: Zone management routes

The system SHALL expose web routes to list zones, start and submit zone
creation, start and submit zone editing, and delete a zone. The system SHALL
NOT expose a dedicated detail ("show") route for a single zone.

#### Scenario: Listing, creating, editing, and deleting are reachable

- **WHEN** a request is made to list zones, to the new-zone form, to create a
  zone, to the edit-zone form, to update a zone, or to delete a zone
- **THEN** the corresponding action handles the request

#### Scenario: No detail route exists

- **WHEN** a request is made to a single zone's detail ("show") route
- **THEN** the system reports no matching route

### Requirement: Zone index listing

The system SHALL display every zone's name alongside controls to edit or
delete that zone, and SHALL display a control to start creating a new zone.

#### Scenario: Index lists all zones with per-row actions

- **GIVEN** at least one zone exists
- **WHEN** the zone index is viewed
- **THEN** every existing zone's name is displayed
- **AND** each zone has an edit control and a delete control

#### Scenario: Index offers a way to create a zone

- **WHEN** the zone index is viewed
- **THEN** a control to start creating a new zone is displayed

### Requirement: Zone creation

The system SHALL let a user submit a name to create a new zone, SHALL keep
the user on the creation form with the invalid input and an error when the
name is blank or already taken by another zone, and SHALL let the user
cancel back to the zone index without creating a zone.

#### Scenario: Creating a zone with a valid name

- **WHEN** the new-zone form is submitted with a non-blank, unused name
- **THEN** the zone is created
- **AND** the user is returned to the zone index, where the new zone appears

#### Scenario: Creating a zone with a blank or duplicate name

- **GIVEN** a zone named "Norte" already exists
- **WHEN** the new-zone form is submitted with a blank name, or with "Norte"
- **THEN** no zone is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Canceling zone creation

- **WHEN** cancel is chosen on the new-zone form
- **THEN** the user is returned to the zone index
- **AND** no zone is created

### Requirement: Zone editing

The system SHALL let a user submit a new name to update an existing zone,
SHALL keep the user on the edit form with the invalid input and an error
when the name is blank or already taken by a different zone, and SHALL let
the user cancel back to the zone index without changing the zone.

#### Scenario: Updating a zone with a valid name

- **GIVEN** a zone exists
- **WHEN** the edit form for that zone is submitted with a non-blank, unused
  name
- **THEN** the zone's name is updated
- **AND** the user is returned to the zone index, where the updated name
  appears

#### Scenario: Updating a zone with a blank or duplicate name

- **GIVEN** two zones exist, one named "Norte" and one named "Sur"
- **WHEN** the edit form for "Sur" is submitted with a blank name, or with
  "Norte"
- **THEN** the zone named "Sur" is not changed
- **AND** the edit form is shown again with a validation error

#### Scenario: Canceling zone editing

- **GIVEN** a zone exists
- **WHEN** cancel is chosen on that zone's edit form
- **THEN** the user is returned to the zone index
- **AND** the zone is not changed

### Requirement: Zone deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with a
cancel option and a confirm option, before deleting a zone. The system SHALL
NOT delete the zone unless the confirm option is chosen. When the confirm
option is chosen for a zone that cannot be deleted because it is still
referenced by other records, the system SHALL leave the zone in place and
SHALL report that the deletion could not be completed.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a zone exists
- **WHEN** the delete control is chosen for that zone
- **THEN** a confirmation prompt is shown with a cancel option and a confirm
  option
- **AND** the zone still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the zone

- **GIVEN** a zone exists and its delete confirmation prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the zone still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion of an unreferenced zone

- **GIVEN** a zone exists with no clients or ordering records referencing it
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the zone is deleted
- **AND** it no longer appears on the zone index

#### Scenario: Confirming deletion of a zone still in use

- **GIVEN** a zone exists that is referenced by at least one client or
  ordering record
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the zone is not deleted
- **AND** the zone index reports that the zone could not be deleted
