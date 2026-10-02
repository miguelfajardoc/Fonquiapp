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

The system SHALL display, for every default product quantity that matches
the active filters and falls on the current page, its client name, zone
name, product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one on the same
row as the filters. Records SHALL be listed by client name, then product
name.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one default product quantity exists and no filter is
  active
- **WHEN** the index is viewed
- **THEN** every record on the current page has its client name, zone name,
  product name, and quantity displayed
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

### Requirement: Default product quantity index filters

The index SHALL offer two optional, combinable filters: a client name text
box and a zone select listing every zone. When both are active, only
records matching both SHALL be listed, and a blank filter SHALL NOT
restrict the list. The client name filter SHALL match records whose
client's name contains the typed text, ignoring letter case and accents,
with typed characters matched literally. The zone filter SHALL match
records belonging to the selected zone. Filters SHALL apply without a
separate submit action (after typing pauses, or when the select changes),
SHALL refresh only the list so the text box keeps focus, and SHALL be
reflected in the page URL. They SHALL NOT be remembered once the user leaves
the index. A control next to the filters SHALL clear them all, showing the
first page of the unfiltered list with every filter control emptied. When
no record matches, the list SHALL show a message saying so.

#### Scenario: Client name filter ignores case and accents

- **GIVEN** default quantities exist for clients "Tienda San José" and
  "Salsamentaria El Paisa"
- **WHEN** the index is filtered by client name "jose"
- **THEN** only the records of "Tienda San José" are listed

#### Scenario: Zone filter lists only that zone's records

- **GIVEN** a default quantity in zone "Bosa" and another in zone "Soacha"
- **WHEN** the index is filtered by zone "Bosa"
- **THEN** only the "Bosa" record is listed

#### Scenario: Filters combine

- **GIVEN** default quantities exist for client "Tienda Norte" in zone
  "Bosa" and for client "Tienda Centro" in zone "Soacha"
- **WHEN** the index is filtered by client name "tienda" and zone "Bosa"
- **THEN** only the "Tienda Norte" record is listed

#### Scenario: No record matches

- **WHEN** the index is filtered by a client name no client contains
- **THEN** no rows are listed
- **AND** a message says no records match the filters

#### Scenario: Clearing the filters

- **GIVEN** the index is filtered by client name and zone
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered list is shown from its first page
- **AND** the client name box and zone select are empty

### Requirement: Default product quantity index pagination

The index SHALL be paginated, showing at most 20 matching records per page,
with controls to move to the previous and next page and to jump to a
specific page. Pagination controls SHALL NOT be shown when all matching
records fit on a single page. Moving between pages SHALL keep the active
filters, and changing a filter SHALL show the first page of the new results.

#### Scenario: Records beyond the first page are on the next page

- **GIVEN** 25 default product quantities exist and no filter is active
- **WHEN** the index is viewed
- **THEN** 20 records are listed with pagination controls
- **WHEN** the next page is opened
- **THEN** the remaining 5 records are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 default product quantities exist
- **WHEN** the index is viewed
- **THEN** all 3 are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filters

- **GIVEN** 25 default quantities in zone "Bosa" and 5 in another zone exist
- **WHEN** the index is filtered by zone "Bosa" and the next page is opened
- **THEN** the remaining 5 "Bosa" records are listed
