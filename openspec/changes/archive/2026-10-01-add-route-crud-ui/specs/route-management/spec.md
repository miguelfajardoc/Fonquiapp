## Purpose

The route management flow is the web interface staff use to list, create,
edit, and remove delivery routes, including building and reordering each
route's list of client stops in one form, without needing console or
database access.

## ADDED Requirements

### Requirement: Route management routes

The system SHALL expose web routes to list routes, start and submit route
creation, start and submit route editing, and delete a route. The system
SHALL NOT expose a dedicated detail ("show") route for a single route.

#### Scenario: Listing, creating, editing, and deleting are reachable

- **WHEN** a request is made to list routes, to the new-route form, to
  create a route, to the edit-route form, to update a route, or to delete a
  route
- **THEN** the corresponding action handles the request

#### Scenario: No detail route exists

- **WHEN** a request is made to a single route's detail ("show") route
- **THEN** the system reports no matching route

### Requirement: Route index listing

The system SHALL display, for every route, its zone's name, its own name,
and the names of its clients in stop order (truncated with an ellipsis when
the full list does not fit), alongside controls to edit or delete that
route, and SHALL display a control to start creating a new route.

#### Scenario: Index lists all routes with their fields and per-row actions

- **GIVEN** at least one route exists, with two client stops
- **WHEN** the route index is viewed
- **THEN** that route's zone name, route name, and both client names in
  stop order are displayed
- **AND** it has an edit control and a delete control

#### Scenario: A long client list is truncated with an ellipsis

- **GIVEN** a route whose stop client names do not all fit in the index row
- **WHEN** the route index is viewed
- **THEN** the displayed client list is truncated and ends with an ellipsis

#### Scenario: Index offers a way to create a route

- **WHEN** the route index is viewed
- **THEN** a control to start creating a new route is displayed

### Requirement: Client stop list editor

On the route creation and editing forms, the system SHALL let a user add a
new client-stop row, remove an existing row, and drag a row to a new
position, entirely before submitting the form. Each row SHALL only offer
clients belonging to the form's currently selected zone. Changing the
selected zone SHALL clear every row already added to the list. Submitting
the form SHALL persist the route's stops in the rows' final on-screen order,
numbering their positions starting at 1 with no gaps.

#### Scenario: A row only offers the selected zone's clients

- **GIVEN** the route form has a zone selected
- **WHEN** a client-stop row is added
- **THEN** that row's client choices are limited to clients belonging to
  the selected zone

#### Scenario: Dragging a row changes the saved order

- **GIVEN** the route form has three client-stop rows, in some order
- **WHEN** the last row is dragged to the first position and the form is
  submitted
- **THEN** the saved route stops reflect that new order

#### Scenario: Removing a row excludes that client

- **GIVEN** the route form has two client-stop rows
- **WHEN** one row is removed and the form is submitted
- **THEN** the saved route has a stop only for the remaining row's client

#### Scenario: Changing the zone clears the rows already added

- **GIVEN** the route form has a zone selected and at least one client-stop
  row added
- **WHEN** a different zone is selected
- **THEN** every client-stop row already added is cleared

#### Scenario: Saved positions match the rows' final order

- **GIVEN** the route form has three client-stop rows arranged in a
  specific order after adding, removing, and dragging rows
- **WHEN** the form is submitted
- **THEN** the saved route stops are numbered 1, 2, and 3 matching that
  final order, with no gaps

### Requirement: Route creation

The system SHALL let a user submit a zone, a name, and an ordered set of
client stops (built with the client stop list editor) to create a new
route, SHALL keep the user on the creation form with the invalid input and
an error when the submission is invalid (per the route's and route stops'
existing validation rules), and SHALL let the user cancel back to the route
index without creating a route.

#### Scenario: Creating a route with valid data

- **GIVEN** a zone and two of its clients exist
- **WHEN** the new-route form is submitted with a non-blank name, that
  zone, and both clients added as stops in a chosen order
- **THEN** the route is created with its stops in that order
- **AND** the user is returned to the route index, where the new route
  appears

#### Scenario: Creating a route with invalid data

- **GIVEN** a zone exists
- **WHEN** the new-route form is submitted with a blank name, with no zone
  selected, with a name already used by another route in the same zone, or
  with a client-stop row referencing a client outside the selected zone
- **THEN** no route or route stop is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Canceling route creation

- **WHEN** cancel is chosen on the new-route form
- **THEN** the user is returned to the route index
- **AND** no route is created

### Requirement: Route editing

The system SHALL pre-fill the edit form with a route's current zone, name,
and client stops in their existing order. The system SHALL let a user
change the name, zone, and stops (via the client stop list editor) and
submit them together, SHALL keep the user on the edit form with the invalid
input and an error when the submission is invalid, and SHALL let the user
cancel back to the route index without changing the route.

#### Scenario: Edit form pre-fills the route's current stops in order

- **GIVEN** a route with two client stops in a specific order
- **WHEN** that route's edit form is opened
- **THEN** both client-stop rows are shown, in that same order

#### Scenario: Updating a route's stops together with its name and zone

- **GIVEN** a route with one client stop
- **WHEN** that route's edit form is submitted with a new name, an added
  second client-stop row, and both rows reordered
- **THEN** the route's name and its stops (including the new one, in the
  submitted order) are updated together

#### Scenario: Updating a route with invalid data

- **GIVEN** a route exists
- **WHEN** that route's edit form is submitted with a blank name, with no
  zone selected, or with a client-stop row referencing a client outside the
  selected zone
- **THEN** the route is not changed
- **AND** the edit form is shown again with a validation error

#### Scenario: Canceling route editing

- **GIVEN** a route exists
- **WHEN** cancel is chosen on that route's edit form
- **THEN** the route is not changed

### Requirement: Route deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with a
cancel option and a confirm option, before deleting a route. The system
SHALL NOT delete the route unless the confirm option is chosen.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a route exists
- **WHEN** the delete control is chosen for that route
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the route still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the route

- **GIVEN** a route exists and its delete confirmation prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the route still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion removes the route and its stops

- **GIVEN** a route with two client stops
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the route and both of its stops are deleted
- **AND** the route no longer appears on the index
