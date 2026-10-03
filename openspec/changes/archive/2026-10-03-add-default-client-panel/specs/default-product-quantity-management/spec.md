## MODIFIED Requirements

### Requirement: Default product quantity index listing

The system SHALL display, for every default product quantity that matches
the active filters and falls on the current page, its client name, zone
name, product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one on the same
row as the filters. Records SHALL be listed by client name, then product
name. Choosing a record's edit control SHALL open that record's edit modal
over the index, regardless of the active filters or page, without leaving
the index.

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

#### Scenario: Edit control opens the edit form from a filtered list

- **GIVEN** the index is filtered by zone and lists a record
- **WHEN** that record's edit control is chosen
- **THEN** that record's edit modal opens over the filtered index
- **AND** the index, its filters, and its current page stay as they were
- **AND** no "content missing" message is shown

### Requirement: Zone-scoped client selection

The creation form SHALL let a user choose a zone, then choose a client
belonging only to that zone. Changing the chosen zone SHALL update the
available clients to that zone's clients and SHALL clear any previously
chosen client.

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
zone), a product, and a quantity to create a new default product quantity.
After a successful submission the user SHALL stay on the creation page: the
new record SHALL appear in that client's default list below the form, and
the form SHALL be reset for the next entry, keeping the same zone and
client and clearing the product and quantity. When the submission is
invalid (per the record's existing validation and uniqueness rules), the
system SHALL keep the user on the creation page with the invalid input and
an error, and SHALL NOT change the client's list. The user SHALL be able to
cancel back to the index without creating a record.

#### Scenario: Creating a record with valid data

- **GIVEN** a zone, a client in that zone, and a product exist, with no
  default product quantity yet for that combination
- **WHEN** the new-record form is submitted with that zone, client,
  product, and a quantity of 0 or more
- **THEN** the record is created
- **AND** the user stays on the creation page, where the new record appears
  in the client's default list
- **AND** the form keeps the same zone and client selected with the product
  and quantity cleared

#### Scenario: Creating several records for the same client in a row

- **GIVEN** a zone, a client in that zone, and two products exist
- **WHEN** the form is submitted for the first product and then, without
  choosing the client again, for the second product
- **THEN** both records are created for that client
- **AND** both appear in the client's default list on the creation page

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

The system SHALL let a user edit an existing default product quantity in a
modal, opened from the index or from the client's default list on the
creation page, without leaving that page. The modal SHALL show the record's
zone and client as fixed values that cannot be changed, and SHALL let the
user change only the product and the quantity. On a successful submission
the modal SHALL close and the record's row SHALL be updated in place on the
page it was opened from. On an invalid submission (per the record's
existing validation and uniqueness rules) the modal SHALL stay open with
the invalid input and an error, and the record SHALL NOT change. Cancelling
SHALL close the modal without changing the record.

#### Scenario: Updating a record with valid data

- **GIVEN** a default product quantity exists
- **WHEN** its edit modal is submitted with a product and a quantity of 0 or
  more, forming a combination not already used by another record for the
  same client and zone
- **THEN** the record is updated
- **AND** the modal closes and the record's row shows the updated product
  and quantity without a page reload

#### Scenario: The modal does not allow changing zone or client

- **GIVEN** a default product quantity exists
- **WHEN** its edit modal is opened
- **THEN** its zone and client are shown but cannot be changed
- **AND** the product and quantity can be changed

#### Scenario: Updating a record into a combination already used by another

- **GIVEN** two default product quantities exist for the same client and
  zone with different products
- **WHEN** one record's edit modal is submitted with the other record's
  product
- **THEN** the record is not changed
- **AND** the modal stays open with a validation error

#### Scenario: Canceling editing

- **GIVEN** a default product quantity's edit modal is open
- **WHEN** cancel is chosen
- **THEN** the modal closes
- **AND** the record is not changed

### Requirement: Default product quantity deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with
a cancel option and a confirm option, before deleting a default product
quantity. The system SHALL NOT delete the record unless the confirm option
is chosen. Confirming SHALL delete the record and remove its row from the
page it was deleted from (the index or the client's default list on the
creation page) without a full page reload.

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
- **AND** its row is removed from the page without a full page reload

## ADDED Requirements

### Requirement: Client default list on the creation page

The creation page SHALL show, below the form, the default product
quantities of the currently chosen client, under a heading naming that
client. Each entry SHALL show the product name and quantity, with an edit
control (opening the edit modal) and a delete control (with confirmation).
Entries SHALL be listed by product name. When the chosen client has none, a
message SHALL say so. When no client is chosen, a prompt to choose a client
SHALL be shown instead of a list. The list SHALL refresh whenever the
client choice changes, and SHALL return to the choose-a-client prompt when
the zone changes (because that clears the client).

#### Scenario: Choosing a client shows its defaults

- **GIVEN** client "Tienda Norte" has default quantities for "Queso" (5)
  and "Crema" (2), and another client has a default for "Suero"
- **WHEN** "Tienda Norte" is chosen on the creation page
- **THEN** a heading naming "Tienda Norte" is shown
- **AND** "Crema" (2) and "Queso" (5) are listed, in that order, each with
  an edit and a delete control
- **AND** "Suero" is not listed

#### Scenario: No client chosen

- **WHEN** the creation page is opened without choosing a client
- **THEN** a prompt to choose a client is shown and no list is displayed

#### Scenario: Chosen client has no defaults

- **GIVEN** a client with no default product quantities
- **WHEN** that client is chosen on the creation page
- **THEN** a message says the client has no defaults

#### Scenario: Changing the zone resets the list

- **GIVEN** a client is chosen and its defaults are listed
- **WHEN** a different zone is chosen
- **THEN** the list is replaced by the prompt to choose a client
