## MODIFIED Requirements

### Requirement: Default product quantity zone and route filters

The index SHALL offer two optional, combinable filters: a zone select
listing every zone and a route select. The route select SHALL offer every
route while no zone is selected and only the routes of the selected zone
otherwise, each shown by its name only, and SHALL be cleared when the zone
changes. Choosing a route SHALL NOT change the zone select. The zone filter SHALL
match records whose route belongs to the selected zone, and the route
filter SHALL match records of the selected route; a route that does not
belong to the selected zone SHALL be ignored. A blank filter SHALL NOT
restrict the list. Filters SHALL apply as soon as a select changes, SHALL
refresh only the list, and SHALL be reflected in the page URL. They SHALL
NOT be remembered once the user leaves the index. A control next to the
filters SHALL clear them all, showing the first page of the unfiltered list
with every filter control emptied. When no record matches, the list SHALL
show a message saying so.

#### Scenario: Zone filter lists only that zone's records

- **GIVEN** a default quantity of a route in zone "Bosa" and another of a
  route in zone "Soacha"
- **WHEN** the index is filtered by zone "Bosa"
- **THEN** only the "Bosa" record is listed

#### Scenario: Route filter lists only that route's records

- **GIVEN** default quantities exist for "Ruta 1" and "Ruta 2" of zone
  "Bosa"
- **WHEN** the index is filtered by zone "Bosa" and route "Ruta 1"
- **THEN** only the "Ruta 1" records are listed

#### Scenario: Route choices follow the selected zone

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha"
  has route "Ruta 3"
- **WHEN** zone "Bosa" is selected in the filters
- **THEN** the route select offers "Ruta 1" and "Ruta 2" only
- **WHEN** no zone is selected
- **THEN** the route select offers "Ruta 1", "Ruta 2" and "Ruta 3"

#### Scenario: Route filter without a zone

- **GIVEN** default quantities exist for "Ruta 1" of zone "Bosa" and "Ruta
  3" of zone "Soacha"
- **WHEN** the index is filtered by route "Ruta 3" with no zone selected
- **THEN** only the "Ruta 3" records are listed
- **AND** the zone select still shows all zones

#### Scenario: No record matches

- **GIVEN** a zone whose routes have no default quantities
- **WHEN** the index is filtered by that zone
- **THEN** no rows are listed
- **AND** a message says no records match the filters

#### Scenario: Clearing the filters

- **GIVEN** the index is filtered by zone and route
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered list is shown from its first page
- **AND** the zone and route selects are empty
