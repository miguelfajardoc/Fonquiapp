## MODIFIED Requirements

### Requirement: Client index listing

The system SHALL display, for every client that matches the active filters
and falls on the current page, its name, address, url, phone, zone name, and
the names of every route it is a stop of (in name order, separated by commas,
and empty when it is a stop of no route), alongside a control to delete that
client, and SHALL display a control to
start creating a new client. Clients SHALL be listed in name order. Selecting
a client elsewhere on its row SHALL open that client's detail view.

#### Scenario: Index lists all clients with their fields and a delete control

- **GIVEN** at least one client exists and no filter is active
- **WHEN** the client index is viewed
- **THEN** every client on the current page has its name, address, url,
  phone, and zone name displayed
- **AND** each client has a delete control

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
- **WHEN** that client's row is selected on the index (other than its delete
  control)
- **THEN** that client's detail view is shown

## ADDED Requirements

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
