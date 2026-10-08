# client-management Specification

## Purpose

The client management flow is the web interface staff use to list, view,
create, edit, and remove clients, without needing console or database
access, while respecting the client's existing validation and
delete-restriction rules and letting a zone be created on the spot instead of
interrupting client entry.

## Requirements

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

The system SHALL display, for every client that matches the active filters
and falls on the current page, its name, address, url, phone, zone name, and
the names of every route it is a stop of (in name order, separated by commas,
and empty when it is a stop of no route), alongside controls to edit or
delete that client, and SHALL display a control to start creating a new
client. Clients SHALL be listed in name order. Choosing a client's edit
control SHALL open that client's edit form as a full page. Selecting a client
elsewhere on its row (other than its edit or delete control) SHALL open that
client's detail view.

#### Scenario: Index lists all clients with their fields and a delete control

- **GIVEN** at least one client exists and no filter is active
- **WHEN** the client index is viewed
- **THEN** every client on the current page has its name, address, url,
  phone, and zone name displayed
- **AND** each client has an edit control and a delete control

#### Scenario: Index shows the routes a client is a stop of

- **GIVEN** client A is a stop of "Ruta 2" and "Ruta 1", and client B is a
  stop of no route
- **WHEN** the client index is viewed
- **THEN** client A's route column shows "Ruta 1, Ruta 2"
- **AND** client B's route column is empty

#### Scenario: Index offers a way to create a client

- **WHEN** the client index is viewed
- **THEN** a control to start creating a new client is displayed

#### Scenario: Selecting a client row opens its detail view

- **GIVEN** a client exists
- **WHEN** that client's row is selected on the index (other than its edit or
  delete control)
- **THEN** that client's detail view is shown

#### Scenario: Edit control opens the client's edit form

- **GIVEN** the client index is filtered and lists a client
- **WHEN** that client's edit control is chosen
- **THEN** that client's edit form is shown as a full page
- **AND** the client's detail view is not opened instead

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

### Requirement: Client index filters

The client index SHALL offer three optional, combinable filters: a name text
box, a zone select listing every zone, and a route select. When several
filters are active, only clients matching all of them SHALL be listed. A
blank filter SHALL NOT restrict the list.

- The name filter SHALL match clients whose name contains the typed text,
  ignoring letter case and accents (diacritics). Characters typed into the
  name box SHALL be matched literally, never treated as wildcards or patterns.
- The zone filter SHALL match clients belonging to the selected zone.
- The route select SHALL offer only the routes of the currently selected
  zone, and SHALL offer no routes while no zone is selected. Changing the
  selected zone SHALL refresh the route choices and clear any chosen route.
  The route filter SHALL match clients that are stops of the selected route.

Filters SHALL apply without a separate submit action: after the user stops
typing in the name box, or as soon as a select changes. Only the client list
area SHALL refresh, so the name box keeps focus while typing. The active
filters SHALL be reflected in the page URL, so reloading the page or
navigating back restores them. Filters SHALL NOT be remembered once the user
leaves the index and returns to it without those URL parameters. A control
next to the filters SHALL clear every filter at once, showing the first page
of the unfiltered list with all filter controls emptied.

#### Scenario: Name filter matches a contained fragment

- **GIVEN** clients named "Tienda La 42" and "Salsamentaria El Paisa" exist
- **WHEN** the client index is filtered by name "tienda"
- **THEN** "Tienda La 42" is listed
- **AND** "Salsamentaria El Paisa" is not listed

#### Scenario: Name filter ignores case and accents

- **GIVEN** clients named "Tienda San José" and "Autoservicio Doña Rosa" exist
- **WHEN** the client index is filtered by name "JOSE"
- **THEN** "Tienda San José" is listed
- **WHEN** the client index is filtered by name "dona"
- **THEN** "Autoservicio Doña Rosa" is listed

#### Scenario: Name filter treats special characters literally

- **GIVEN** clients named "Tienda 100%" and "Tienda 1000" exist
- **WHEN** the client index is filtered by name "100%"
- **THEN** "Tienda 100%" is listed
- **AND** "Tienda 1000" is not listed

#### Scenario: Zone filter lists only that zone's clients

- **GIVEN** client A belongs to zone "Bosa" and client B belongs to zone "Soacha"
- **WHEN** the client index is filtered by zone "Bosa"
- **THEN** client A is listed
- **AND** client B is not listed

#### Scenario: Route choices follow the selected zone

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha" has
  route "Ruta 3"
- **WHEN** the client index is viewed with no zone selected
- **THEN** the route select offers no routes
- **WHEN** zone "Bosa" is selected
- **THEN** the route select offers "Ruta 1" and "Ruta 2" only
- **WHEN** the selection is changed to zone "Soacha"
- **THEN** the route select offers "Ruta 3" only and no route is chosen

#### Scenario: Route filter lists only that route's stops

- **GIVEN** zone "Bosa" has clients A and B, and only client A is a stop of
  "Ruta 1"
- **WHEN** the client index is filtered by zone "Bosa" and route "Ruta 1"
- **THEN** client A is listed
- **AND** client B is not listed

#### Scenario: A client on several routes appears once

- **GIVEN** client A is a stop of a route that is selected in the route filter
- **WHEN** the client index is filtered by that route
- **THEN** client A is listed exactly once

#### Scenario: Filters combine

- **GIVEN** zone "Bosa" has clients "Tienda Norte" and "Tienda Sur", and
  zone "Soacha" has client "Tienda Centro"
- **WHEN** the client index is filtered by name "tienda" and zone "Bosa"
- **THEN** "Tienda Norte" and "Tienda Sur" are listed
- **AND** "Tienda Centro" is not listed

#### Scenario: No client matches

- **GIVEN** no client name contains "zzz"
- **WHEN** the client index is filtered by name "zzz"
- **THEN** no client rows are listed
- **AND** a message says no clients match the filters

#### Scenario: Clearing the filters

- **GIVEN** the client index is filtered by name, zone, and route
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered client list is shown from its first page
- **AND** the name box, zone select, and route select are empty

#### Scenario: Filters are kept in the URL

- **GIVEN** the client index is filtered by name "tienda" and a zone
- **WHEN** the page is reloaded
- **THEN** the same filters are still applied and shown in the filter bar

### Requirement: Client index pagination

The client index SHALL be paginated, showing at most 20 matching clients per
page, with controls to move to the previous and next page and to jump to a
specific page. Pagination controls SHALL NOT be shown when all matching
clients fit on a single page. Moving between pages SHALL keep the active
filters, and changing a filter SHALL show the first page of the new results.

#### Scenario: Clients beyond the first page are on the next page

- **GIVEN** 25 clients exist and no filter is active
- **WHEN** the client index is viewed
- **THEN** the first 20 clients in name order are listed
- **AND** pagination controls are displayed
- **WHEN** the next page is opened
- **THEN** the remaining 5 clients are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 clients exist
- **WHEN** the client index is viewed
- **THEN** all 3 clients are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filters

- **GIVEN** 25 clients in zone "Bosa" and 5 clients in another zone exist
- **WHEN** the client index is filtered by zone "Bosa" and the next page is
  opened
- **THEN** the remaining 5 "Bosa" clients are listed
- **AND** no client from the other zone is listed

#### Scenario: Changing a filter returns to the first page

- **GIVEN** the client index is showing page 2 of unfiltered results
- **WHEN** a filter is changed
- **THEN** the first page of the filtered results is shown
