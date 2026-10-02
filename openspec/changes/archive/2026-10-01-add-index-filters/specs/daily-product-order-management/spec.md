## MODIFIED Requirements

### Requirement: Grouped batch listing

The index page SHALL list every day+route combination that has at least
one daily product order and matches the active table filters, grouped into
one row per combination, showing that day, the route's zone, and the
route's name, and offering a control to download that batch's consolidated
spreadsheet. Rows SHALL be ordered by the time the batch was last
generated, most recent first, so a batch that was just generated or
regenerated is listed at the top.

#### Scenario: Each generated batch appears once

- **GIVEN** a route was generated today, producing daily product orders for
  three different client+product combinations
- **WHEN** the index is viewed
- **THEN** exactly one row is shown for today's generation of that route,
  showing today's date, the route's zone name, and the route's name

#### Scenario: Different batches are listed separately

- **GIVEN** two different routes of the same zone were each generated today
- **WHEN** the index is viewed
- **THEN** one row is shown for each route's batch

#### Scenario: Batches are ordered newest first

- **GIVEN** a route was generated yesterday and another route was generated
  today
- **WHEN** the index is viewed
- **THEN** today's batch is listed above yesterday's batch

#### Scenario: A just-generated batch is listed first within the same day

- **GIVEN** route "Ruta A" of zone "Bosa" was generated earlier today
- **WHEN** route "Ruta Z" of zone "Soacha" is generated afterward today and
  the index is shown
- **THEN** the "Ruta Z" batch is listed above the "Ruta A" batch

#### Scenario: Regenerating a batch moves it to the top

- **GIVEN** "Ruta A" and then "Ruta B" were generated today
- **WHEN** "Ruta A" is generated again today and the index is shown
- **THEN** the "Ruta A" batch is listed above the "Ruta B" batch

## ADDED Requirements

### Requirement: Batch table filters

The index page SHALL offer table filters, presented separately from the
generation controls (below them and visually distinguished), consisting of
a zone select listing every zone and a route select. The route select SHALL
offer only the routes of the zone selected in the table filters, SHALL offer
no routes while no zone is selected, and SHALL be cleared when that zone
changes. The zone filter SHALL list only batches of routes in the selected
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
- **THEN** the table route select offers no routes

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
