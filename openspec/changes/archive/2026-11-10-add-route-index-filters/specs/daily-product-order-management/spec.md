## MODIFIED Requirements

### Requirement: Batch table filters

The index page SHALL offer table filters, presented separately from the
generation controls (below them and visually distinguished), consisting of
a zone select listing every zone and a route select. The route select SHALL
offer every route while no zone is selected in the table filters and only
the routes of that zone otherwise, each shown by its name only, and SHALL be
cleared when that zone changes. Choosing a route SHALL NOT change the table
zone select. The zone filter SHALL list only batches of routes in the selected
zone, and the route filter only batches of the selected route. A route that
does not belong to the selected zone SHALL be ignored. The table filters
SHALL be independent of the generation controls: changing one SHALL NOT
change the other's selection. Filters SHALL apply as soon as a select
changes, SHALL refresh only the batch list, and SHALL be reflected in the
page URL. They SHALL NOT be remembered once the user leaves the index.
Moving between pages SHALL keep the active table filters, and changing a
filter SHALL show the first page. A control next to the table filters SHALL
clear them, showing the first page of all batches with both filter selects
emptied. When no batch matches, the list SHALL show a message saying so.

#### Scenario: Zone filter lists only that zone's batches

- **GIVEN** batches exist for a route in zone "Bosa" and a route in zone
  "Soacha"
- **WHEN** the batch table is filtered by zone "Bosa"
- **THEN** only the "Bosa" batch is listed

#### Scenario: Route filter lists only that route's batches

- **GIVEN** batches exist for "Ruta 1" and "Ruta 2" of zone "Bosa"
- **WHEN** the batch table is filtered by zone "Bosa" and route "Ruta 1"
- **THEN** only the "Ruta 1" batches are listed

#### Scenario: Table route choices follow the table zone

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha"
  has route "Ruta 3"
- **WHEN** zone "Bosa" is selected in the table filters
- **THEN** the table route select offers "Ruta 1" and "Ruta 2" only
- **WHEN** no zone is selected in the table filters
- **THEN** the table route select offers "Ruta 1", "Ruta 2" and "Ruta 3"

#### Scenario: Table route filter without a zone

- **GIVEN** batches exist for "Ruta 1" of zone "Bosa" and "Ruta 3" of zone
  "Soacha"
- **WHEN** the batch table is filtered by route "Ruta 3" with no zone
  selected
- **THEN** only the "Ruta 3" batches are listed
- **AND** the table zone select still shows all zones

#### Scenario: Generation route choices still wait for a zone

- **WHEN** the index is viewed with no zone selected in the generation
  controls
- **THEN** the generation route select offers no routes

#### Scenario: Table filters and generation controls are independent

- **GIVEN** zone "Soacha" is selected in the generation controls
- **WHEN** the batch table is filtered by zone "Bosa"
- **THEN** the generation controls still have "Soacha" selected and offer
  "Soacha"'s routes

#### Scenario: Clearing the table filters

- **GIVEN** the batch table is filtered by zone and route
- **WHEN** the clear-filters control is chosen
- **THEN** all batches are shown from the first page
- **AND** both table filter selects are empty
