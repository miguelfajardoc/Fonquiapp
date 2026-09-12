# default-product-quantity-management Specification

## Purpose

The default product quantity management flow is the web interface staff use
to list, create, edit, and remove standing default quantities (per
client+zone+product), without needing console or database access, while
respecting the record's existing validation and uniqueness rules.

## Requirements

### Requirement: Default product quantity management routes

The system SHALL expose web routes to list default product quantities,
start and submit creation, start and submit editing, and delete a default
product quantity. The system SHALL NOT expose a dedicated detail ("show")
route for a single default product quantity.

#### Scenario: Listing, creating, editing, and deleting are reachable

- **WHEN** a request is made to list default product quantities, to the
  new form, to create one, to the edit form, to update one, or to delete
  one
- **THEN** the corresponding action handles the request

#### Scenario: No detail route exists

- **WHEN** a request is made to a single default product quantity's
  detail ("show") route
- **THEN** the system reports no matching route

### Requirement: Default product quantity index listing

The system SHALL display every default product quantity's client name,
product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one default product quantity exists
- **WHEN** the index is viewed
- **THEN** every existing record's client name, product name, and
  quantity are displayed
- **AND** each record has an edit control and a delete control

#### Scenario: Index offers a way to create a record

- **WHEN** the index is viewed
- **THEN** a control to start creating a new default product quantity is
  displayed

### Requirement: Zone-scoped client selection

The creation and editing forms SHALL let a user choose a zone, then choose
a client belonging only to that zone. Changing the chosen zone SHALL
update the available clients to that zone's clients and SHALL clear any
previously chosen client.

#### Scenario: Client choices are limited to the chosen zone

- **GIVEN** clients exist in two different zones
- **WHEN** a zone is chosen on the creation form
- **THEN** only clients belonging to that zone can be chosen as the client

#### Scenario: Changing the zone clears the chosen client

- **GIVEN** a zone is chosen and a client belonging to it has been chosen
- **WHEN** a different zone is chosen
- **THEN** the client choice is cleared
- **AND** only the new zone's clients can be chosen as the client

### Requirement: Default product quantity creation

The system SHALL let a user submit a zone, a client (belonging to that
zone), a product, and a quantity to create a new default product
quantity, SHALL keep the user on the creation form with the invalid input
and an error when the submission is invalid (per the record's existing
validation and uniqueness rules), and SHALL let the user cancel back to
the index without creating a record.

#### Scenario: Creating a record with valid data

- **GIVEN** a zone, a client in that zone, and a product exist, with no
  default product quantity yet for that combination
- **WHEN** the new-record form is submitted with that zone, client,
  product, and a quantity of 0 or more
- **THEN** the record is created
- **AND** the user is returned to the index, where the new record appears

#### Scenario: Creating a record for a combination that already has one

- **GIVEN** a default product quantity already exists for a
  product+client+zone combination
- **WHEN** the new-record form is submitted for that same combination
- **THEN** no record is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Creating a record with a negative or non-integer quantity

- **WHEN** the new-record form is submitted with a negative or
  non-integer quantity
- **THEN** no record is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Canceling creation

- **WHEN** cancel is chosen on the new-record form
- **THEN** the user is returned to the index
- **AND** no record is created

### Requirement: Default product quantity editing

The system SHALL let a user submit a new zone, client, product, and/or
quantity to update an existing default product quantity, SHALL keep the
user on the edit form with the invalid input and an error when the
submission is invalid (per the record's existing validation and
uniqueness rules), and SHALL let the user cancel back to the index without
changing the record.

#### Scenario: Updating a record with valid data

- **GIVEN** a default product quantity exists
- **WHEN** its edit form is submitted with a valid zone, client (in that
  zone), product, and a quantity of 0 or more, forming a combination not
  already used by another record
- **THEN** the record is updated
- **AND** the user is returned to the index, where the updated values
  appear

#### Scenario: Updating a record into a combination already used by another

- **GIVEN** two default product quantities exist for two different
  combinations
- **WHEN** one record's edit form is submitted with the other record's
  product+client+zone combination
- **THEN** the record is not changed
- **AND** the edit form is shown again with a validation error

#### Scenario: Canceling editing

- **GIVEN** a default product quantity exists
- **WHEN** cancel is chosen on its edit form
- **THEN** the user is returned to the index
- **AND** the record is not changed

### Requirement: Default product quantity deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with
a cancel option and a confirm option, before deleting a default product
quantity. The system SHALL NOT delete the record unless the confirm
option is chosen.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a default product quantity exists
- **WHEN** the delete control is chosen for that record
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the record still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the record

- **GIVEN** a default product quantity exists and its delete confirmation
  prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the record still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion removes the record

- **GIVEN** a default product quantity exists
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the record is deleted
- **AND** it no longer appears on the index
