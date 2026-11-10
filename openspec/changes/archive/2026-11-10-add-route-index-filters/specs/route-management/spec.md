## MODIFIED Requirements

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

## ADDED Requirements

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
