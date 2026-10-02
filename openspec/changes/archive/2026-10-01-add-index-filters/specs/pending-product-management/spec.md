## MODIFIED Requirements

### Requirement: Pending product index listing

The system SHALL display, for every pending product that matches the active
filters and falls on the current page, its creation date, client name, zone
name, product name, quantity, and state, alongside controls to edit, delete,
and toggle the state of that record, and SHALL display a control to start
creating a new one on the same row as the filters. Records SHALL be listed
by creation date in the selected sort direction, most recent first by
default. The "Pendiente" and "Entregado" states SHALL each be shown with
their own distinguishing color; the "Cancelado" state SHALL be shown with
no highlight color.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one pending product exists
- **WHEN** the index is viewed with "Todos los estados" selected and no other
  filter active
- **THEN** every record on the current page has its creation date, client
  name, zone name, product name, quantity, and state displayed
- **AND** each record has an edit control, a delete control, and a state
  toggle control

#### Scenario: Index offers a way to create a record

- **WHEN** the index is viewed
- **THEN** a control to start creating a new pending product is displayed

#### Scenario: Pendiente and Entregado states are visually distinguished

- **GIVEN** one pending product with state "Pendiente" and another with
  state "Entregado"
- **WHEN** the index is viewed with "Todos los estados" selected
- **THEN** the two records' state values are shown with different
  highlight colors from each other

#### Scenario: Cancelado state has no highlight color

- **GIVEN** a pending product with state "Cancelado"
- **WHEN** the index is viewed with "Todos los estados" selected
- **THEN** that record's state value is shown with no highlight color

## ADDED Requirements

### Requirement: Pending product index filters and sort

The index SHALL offer three optional, combinable filters, which are a zone
select listing every zone, a client name text box, and a state select
offering "Todos los estados", "Pendiente", "Entregado", and "Cancelado", and a
creation-date sort select offering "Más recientes primero" (the default) and
"Más antiguos primero". When no state has been chosen (for example on first
visit), the state filter SHALL default to "Pendiente"; choosing "Todos los
estados" SHALL list records in every state. When several filters are active, only records matching all of
them SHALL be listed, and a blank filter SHALL NOT restrict the list. The
client name filter SHALL match records whose client's name contains the
typed text, ignoring letter case and accents, with typed characters matched
literally. The zone filter SHALL match records belonging to the selected
zone, and the state filter records in the selected state. Filters and the
sort SHALL apply without a separate submit action (after typing pauses, or
when a select changes), SHALL refresh only the list so the text box keeps
focus, and SHALL be reflected in the page URL. They SHALL NOT be remembered
once the user leaves the index. A control next to the filters SHALL clear
them all and restore the defaults (state "Pendiente", most recent first),
showing the first page with the zone and client name controls emptied. When no record matches, the list SHALL show a
message saying so. Toggling a listed record's state SHALL keep updating
that row in place.

#### Scenario: Client name filter ignores case and accents

- **GIVEN** pending products exist for clients "Tienda San José" and
  "Salsamentaria El Paisa"
- **WHEN** the index is filtered by client name "JOSE"
- **THEN** only the records of "Tienda San José" are listed

#### Scenario: Zone filter lists only that zone's records

- **GIVEN** a pending product in zone "Bosa" and another in zone "Soacha"
- **WHEN** the index is filtered by zone "Bosa"
- **THEN** only the "Bosa" record is listed

#### Scenario: State filter defaults to Pendiente

- **GIVEN** pending products in the states "Pendiente", "Entregado", and
  "Cancelado"
- **WHEN** the index is viewed with no state chosen
- **THEN** only the "Pendiente" record is listed
- **AND** the state select shows "Pendiente"

#### Scenario: All states lists every record

- **GIVEN** pending products in the states "Pendiente", "Entregado", and
  "Cancelado"
- **WHEN** the index is filtered by "Todos los estados"
- **THEN** all three records are listed

#### Scenario: State filter lists only records in that state

- **GIVEN** pending products in the states "Pendiente", "Entregado", and
  "Cancelado"
- **WHEN** the index is filtered by state "Entregado"
- **THEN** only the "Entregado" record is listed

#### Scenario: Filters combine

- **GIVEN** in zone "Bosa" a "Pendiente" and an "Entregado" pending product,
  and in zone "Soacha" a "Pendiente" pending product
- **WHEN** the index is filtered by zone "Bosa" and state "Pendiente"
- **THEN** only the "Bosa" "Pendiente" record is listed

#### Scenario: Default sort lists the most recent first

- **GIVEN** a pending product created yesterday and another created today
- **WHEN** the index is viewed with no sort chosen
- **THEN** today's record is listed above yesterday's

#### Scenario: Oldest-first sort reverses the order

- **GIVEN** a pending product created yesterday and another created today
- **WHEN** the index is sorted by "Más antiguos primero"
- **THEN** yesterday's record is listed above today's

#### Scenario: No record matches

- **WHEN** the index is filtered by a client name no client contains
- **THEN** no rows are listed
- **AND** a message says no records match the filters

#### Scenario: Clearing the filters

- **GIVEN** the index is filtered by zone, client name, and state and sorted
  oldest first
- **WHEN** the clear-filters control is chosen
- **THEN** the list is shown from its first page with only "Pendiente"
  records, most recent first
- **AND** the zone and client name controls are empty and the state select
  shows "Pendiente"

### Requirement: Pending product index pagination

The index SHALL be paginated, showing at most 20 matching records per page,
with controls to move to the previous and next page and to jump to a
specific page. Pagination controls SHALL NOT be shown when all matching
records fit on a single page. Moving between pages SHALL keep the active
filters and sort, and changing a filter or the sort SHALL show the first
page of the new results.

#### Scenario: Records beyond the first page are on the next page

- **GIVEN** 25 pending products exist and no filter is active
- **WHEN** the index is viewed
- **THEN** the 20 most recent records are listed with pagination controls
- **WHEN** the next page is opened
- **THEN** the remaining 5 records are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 pending products exist
- **WHEN** the index is viewed
- **THEN** all 3 are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filters and sort

- **GIVEN** 25 pending products in state "Pendiente" and 5 in state
  "Entregado" exist
- **WHEN** the index is filtered by state "Pendiente", sorted oldest first,
  and the next page is opened
- **THEN** the 5 most recent "Pendiente" records are listed, oldest first
