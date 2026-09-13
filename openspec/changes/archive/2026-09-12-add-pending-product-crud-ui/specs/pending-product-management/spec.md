## Purpose

The pending product management flow is the web interface staff use to list,
create, edit, mark delivered, and delete pending product deliveries for a client,
without needing console or database access.

## ADDED Requirements

### Requirement: Pending product management routes

The system SHALL expose web routes to list pending products, start and
submit creation, start and submit editing, and delete a pending product.
The system SHALL NOT expose a dedicated detail ("show") route for a single
pending product.

#### Scenario: Listing, creating, editing, and deleting are reachable

- **WHEN** a request is made to list pending products, to the new form, to
  create one, to the edit form, to update one, or to delete one
- **THEN** the corresponding action handles the request

#### Scenario: No detail route exists

- **WHEN** a request is made to a single pending product's detail ("show")
  route
- **THEN** the system reports no matching route

### Requirement: Pending product index listing

The system SHALL display every pending product's creation date, client
name, product name, quantity, and state, alongside controls to edit,
delete, and toggle the state of that record, and SHALL display a control
to start creating a new one. The "Pendiente" and "Entregado" states SHALL
each be shown with their own distinguishing color; the "Cancelado" state
SHALL be shown with no highlight color.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one pending product exists
- **WHEN** the index is viewed
- **THEN** every existing record's creation date, client name, product
  name, quantity, and state are displayed
- **AND** each record has an edit control, a delete control, and a state
  toggle control

#### Scenario: Index offers a way to create a record

- **WHEN** the index is viewed
- **THEN** a control to start creating a new pending product is displayed

#### Scenario: Pendiente and Entregado states are visually distinguished

- **GIVEN** one pending product with state "Pendiente" and another with
  state "Entregado"
- **WHEN** the index is viewed
- **THEN** the two records' state values are shown with different
  highlight colors from each other

#### Scenario: Cancelado state has no highlight color

- **GIVEN** a pending product with state "Cancelado"
- **WHEN** the index is viewed
- **THEN** that record's state value is shown with no highlight color

### Requirement: Searchable client selection

The creation form SHALL let a user find and choose a client by searching,
rather than by scrolling a plain list, to remain usable as the number of
clients grows.

#### Scenario: Client can be found by searching

- **GIVEN** many clients exist
- **WHEN** the user searches for a client by (partial) name on the
  creation form
- **THEN** matching clients are offered as choices

### Requirement: Pending product creation with live client-scoped list

The creation page SHALL let a user submit a client, a product, and a
quantity to create a new pending product with state "Pendiente", using the
client's own zone. The page SHALL keep the user on the creation form with
the invalid input and an error when the submission is invalid (per the
record's existing validation rules).

Below the creation form, the page SHALL display the chosen client's
pending products (creation date, product, quantity, state, and the same
edit/delete/toggle actions as the index), labeled with that client's name,
and SHALL update this list without a full page reload whenever: the chosen
client changes, a new pending product is created, an existing one is
edited, or an existing one's state is toggled.

#### Scenario: Creating a record with valid data

- **GIVEN** a client and a product exist
- **WHEN** the creation form is submitted with that client, product, and a
  quantity greater than 0
- **THEN** the pending product is created with state "Pendiente" and the
  chosen client's zone
- **AND** it appears in the client-scoped list below, without the page
  reloading

#### Scenario: Creating a record with an invalid quantity

- **WHEN** the creation form is submitted with a quantity of 0, a negative
  quantity, or a non-integer quantity
- **THEN** no pending product is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Choosing a client shows that client's pending products

- **GIVEN** a client has existing pending products
- **WHEN** that client is chosen on the creation form
- **THEN** the list below updates, without a full page reload, to show
  that client's pending products under a heading naming that client

#### Scenario: Changing the chosen client updates the list

- **GIVEN** the list below currently shows one client's pending products
- **WHEN** a different client is chosen on the creation form
- **THEN** the list below updates, without a full page reload, to show the
  newly chosen client's pending products instead

### Requirement: Shared edit modal

Editing a pending product, from either the index or the creation page's
client-scoped list, SHALL open a modal containing the edit form. Submitting
the modal SHALL update the record and the underlying list in place without
navigating away or reloading the page. Canceling SHALL close the modal
without changing the record.

#### Scenario: Editing from the index updates the row in place

- **GIVEN** a pending product exists
- **WHEN** its edit control is chosen from the index, the modal form is
  submitted with valid data, and the modal closes
- **THEN** the record is updated
- **AND** the index row reflects the new data without the page reloading

#### Scenario: Editing from the creation page's list updates it in place

- **GIVEN** a pending product exists and its client is chosen on the
  creation page, showing it in the client-scoped list
- **WHEN** its edit control is chosen from that list, the modal form is
  submitted with valid data, and the modal closes
- **THEN** the record is updated
- **AND** the client-scoped list reflects the new data without the page
  reloading

#### Scenario: Submitting invalid data keeps the modal open with an error

- **GIVEN** a pending product's edit modal is open
- **WHEN** the form is submitted with invalid data
- **THEN** the record is not changed
- **AND** the modal remains open showing a validation error

#### Scenario: Canceling the edit modal keeps the record unchanged

- **GIVEN** a pending product's edit modal is open
- **WHEN** cancel is chosen
- **THEN** the modal closes
- **AND** the record is not changed

### Requirement: State toggle between Pendiente and Entregado

The system SHALL let a user toggle a pending product's state between
"Pendiente" and "Entregado" from its toggle control, from either the index
or the creation page's client-scoped list, without a full page reload. The
toggle SHALL NOT set or clear the "Cancelado" state.

#### Scenario: Toggling a Pendiente record marks it delivered

- **GIVEN** a pending product with state "Pendiente"
- **WHEN** its toggle control is chosen
- **THEN** its state becomes "Entregado"
- **AND** the list it appears in reflects the new state without the page
  reloading

#### Scenario: Toggling an Entregado record reverts it to Pendiente

- **GIVEN** a pending product with state "Entregado"
- **WHEN** its toggle control is chosen
- **THEN** its state becomes "Pendiente"

### Requirement: Pending product deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with
a cancel option and a confirm option, before deleting a pending product.
The system SHALL NOT delete the record unless the confirm option is
chosen.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a pending product exists
- **WHEN** the delete control is chosen for that record
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the record still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the record

- **GIVEN** a pending product exists and its delete confirmation prompt is
  open
- **WHEN** the cancel option is chosen
- **THEN** the record still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion removes the record

- **GIVEN** a pending product exists
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the record is deleted
- **AND** it no longer appears on the index
