# route-management Specification

## Purpose

The route management flow is the web interface staff use to list, create,
edit, and remove delivery routes, including building and reordering each
route's list of client stops in one form, without needing console or
database access.

## Requirements

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

The system SHALL display, for every listed route, its zone's name, its own
name, and the names of all its clients in stop order (truncated with an
ellipsis when the full list does not fit), alongside controls to edit or
delete that route, and SHALL display a control to start creating a new
route. Routes SHALL be listed by zone name, then by route name.

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

#### Scenario: Routes are ordered by zone and name

- **GIVEN** zone "Soacha" has route "Ruta 1" and zone "Bosa" has routes
  "Ruta 2" and "Ruta 1"
- **WHEN** the route index is viewed
- **THEN** the routes are listed as "Bosa / Ruta 1", "Bosa / Ruta 2",
  "Soacha / Ruta 1"

### Requirement: Route index filters

The route index SHALL offer three optional, combinable filters: a zone
select listing every zone, a route select, and a client search box that
suggests clients by name as the user types and lets the user pick one
client. When several filters are active, only routes matching all of them
SHALL be listed. A blank filter SHALL NOT restrict the list.

- The zone filter SHALL match routes of the selected zone.
- The route select SHALL offer every route while no zone is selected, and
  only the routes of the selected zone otherwise, each shown by its name
  only. Changing the selected zone SHALL refresh the route choices and clear
  any chosen route. Choosing a route SHALL NOT change the zone select. The
  route filter SHALL match the selected route; a route that does not belong
  to the selected zone SHALL be ignored.
- The client search box SHALL suggest every client whose name contains the
  typed text, regardless of the selected zone. The client filter SHALL match
  routes that have the chosen client as a stop. Each matching route SHALL
  still show all of its clients. Removing the chosen client SHALL remove the
  client filter.

Filters SHALL apply without a separate submit action, as soon as a select
changes or a client is chosen or removed. Only the route list area SHALL
refresh. The active filters SHALL be reflected in the page URL, so reloading
the page or navigating back restores them, including the chosen client's
name in the search box. Filters SHALL NOT be remembered once the user leaves
the index and returns to it without those URL parameters. A control next to
the filters SHALL clear every filter at once, showing the first page of the
unfiltered list with all filter controls emptied. When no route matches,
the list SHALL show a message saying so.

#### Scenario: Zone filter lists only that zone's routes

- **GIVEN** route "Ruta 1" of zone "Bosa" and route "Ruta 3" of zone
  "Soacha"
- **WHEN** the route index is filtered by zone "Bosa"
- **THEN** "Ruta 1" is listed
- **AND** "Ruta 3" is not listed

#### Scenario: Route choices list every route until a zone is chosen

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha"
  has route "Ruta 3"
- **WHEN** the route index is viewed with no zone selected
- **THEN** the route select offers "Ruta 1", "Ruta 2" and "Ruta 3"
- **WHEN** zone "Bosa" is selected
- **THEN** the route select offers "Ruta 1" and "Ruta 2" only and no route
  is chosen

#### Scenario: Route filter without a zone

- **GIVEN** routes "Ruta 1" of zone "Bosa" and "Ruta 3" of zone "Soacha"
- **WHEN** the route index is filtered by route "Ruta 3" with no zone
  selected
- **THEN** only "Ruta 3" is listed
- **AND** the zone select still shows all zones

#### Scenario: A route outside the selected zone is ignored

- **GIVEN** route "Ruta 3" belongs to zone "Soacha"
- **WHEN** the route index is filtered by zone "Bosa" and route "Ruta 3"
- **THEN** every route of "Bosa" is listed

#### Scenario: Client filter lists the routes that stop at that client

- **GIVEN** client "Tienda Norte" is a stop of "Ruta 1" and "Ruta 2", and
  "Ruta 3" has other clients only
- **WHEN** the route index is filtered by client "Tienda Norte"
- **THEN** "Ruta 1" and "Ruta 2" are listed, each once, with all of their
  clients
- **AND** "Ruta 3" is not listed

#### Scenario: Client suggestions ignore the zone filter

- **GIVEN** zone "Bosa" is selected and client "Tienda Sur" belongs to zone
  "Soacha"
- **WHEN** "sur" is typed in the client search box
- **THEN** "Tienda Sur" is suggested

#### Scenario: Filters combine

- **GIVEN** client "Tienda Norte" is a stop of route "Ruta 1" of zone
  "Bosa" and of route "Ruta 3" of zone "Soacha"
- **WHEN** the route index is filtered by zone "Bosa" and client "Tienda
  Norte"
- **THEN** only "Ruta 1" is listed

#### Scenario: No route matches

- **GIVEN** a client who is a stop of no route
- **WHEN** the route index is filtered by that client
- **THEN** no route rows are listed
- **AND** a message says no routes match the filters

#### Scenario: Filters are kept in the URL

- **GIVEN** the route index is filtered by a zone and by client "Tienda
  Norte"
- **WHEN** the page is reloaded
- **THEN** the same filters are still applied
- **AND** the client search box shows "Tienda Norte"

#### Scenario: Clearing the filters

- **GIVEN** the route index is filtered by zone, route and client
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered route list is shown from its first page
- **AND** the zone select, route select and client search box are empty

### Requirement: Route index pagination

The route index SHALL be paginated, showing at most 20 matching routes per
page, with controls to move to the previous and next page and to jump to a
specific page. Pagination controls SHALL NOT be shown when all matching
routes fit on a single page. Moving between pages SHALL keep the active
filters, and changing a filter SHALL show the first page of the new results.

#### Scenario: Routes beyond the first page are on the next page

- **GIVEN** 25 routes exist and no filter is active
- **WHEN** the route index is viewed
- **THEN** the first 20 routes in zone and name order are listed
- **AND** pagination controls are displayed
- **WHEN** the next page is opened
- **THEN** the remaining 5 routes are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 routes exist
- **WHEN** the route index is viewed
- **THEN** all 3 routes are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filters

- **GIVEN** 25 routes in zone "Bosa" and 5 routes in another zone exist
- **WHEN** the route index is filtered by zone "Bosa" and the next page is
  opened
- **THEN** the remaining 5 "Bosa" routes are listed

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
SHALL NOT delete the route unless the confirm option is chosen. When the
route cannot be deleted because daily product orders reference it, the
system SHALL keep the route, return the user to the route index, and show
an error explaining why it was not deleted.

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

- **GIVEN** a route with two client stops and no daily product orders
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the route and both of its stops are deleted
- **AND** the route no longer appears on the index

#### Scenario: Deleting a route with daily product orders shows an error

- **GIVEN** a route referenced by a daily product order
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the route and its stops still exist
- **AND** the user is returned to the route index with an error explaining
  the route could not be deleted
