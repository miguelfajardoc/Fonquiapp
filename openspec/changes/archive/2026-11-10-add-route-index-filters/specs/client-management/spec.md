## MODIFIED Requirements

### Requirement: Client index filters

The client index SHALL offer three optional, combinable filters: a name text
box, a zone select listing every zone, and a route select. When several
filters are active, only clients matching all of them SHALL be listed. A
blank filter SHALL NOT restrict the list.

- The name filter SHALL match clients whose name contains the typed text,
  ignoring letter case and accents (diacritics). Characters typed into the
  name box SHALL be matched literally, never treated as wildcards or patterns.
- The zone filter SHALL match clients belonging to the selected zone.
- The route select SHALL offer every route while no zone is selected, and
  only the routes of the currently selected zone otherwise, each shown by its
  name only. Changing the selected zone SHALL refresh the route choices and
  clear any chosen route. Choosing a route SHALL NOT change the zone select.
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
- **THEN** the route select offers "Ruta 1", "Ruta 2" and "Ruta 3"
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

#### Scenario: Route filter without a zone

- **GIVEN** client A is a stop of "Ruta 3" of zone "Soacha" and client B is
  not
- **WHEN** the client index is filtered by route "Ruta 3" with no zone
  selected
- **THEN** client A is listed
- **AND** client B is not listed
- **AND** the zone select still shows all zones

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
