## MODIFIED Requirements

### Requirement: Default product quantity index listing

The system SHALL display, for every default product quantity that matches
the active filters and falls on the current page, its client name, zone
name, product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one on the same
row as the filters. Records SHALL be listed by client name, then product
name.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one default product quantity exists and no filter is
  active
- **WHEN** the index is viewed
- **THEN** every record on the current page has its client name, zone name,
  product name, and quantity displayed
- **AND** each record has an edit control and a delete control

#### Scenario: Index offers a way to create a record

- **WHEN** the index is viewed
- **THEN** a control to start creating a new default product quantity is
  displayed

## ADDED Requirements

### Requirement: Default product quantity index filters

The index SHALL offer two optional, combinable filters: a client name text
box and a zone select listing every zone. When both are active, only
records matching both SHALL be listed, and a blank filter SHALL NOT
restrict the list. The client name filter SHALL match records whose
client's name contains the typed text, ignoring letter case and accents,
with typed characters matched literally. The zone filter SHALL match
records belonging to the selected zone. Filters SHALL apply without a
separate submit action (after typing pauses, or when the select changes),
SHALL refresh only the list so the text box keeps focus, and SHALL be
reflected in the page URL. They SHALL NOT be remembered once the user leaves
the index. A control next to the filters SHALL clear them all, showing the
first page of the unfiltered list with every filter control emptied. When
no record matches, the list SHALL show a message saying so.

#### Scenario: Client name filter ignores case and accents

- **GIVEN** default quantities exist for clients "Tienda San José" and
  "Salsamentaria El Paisa"
- **WHEN** the index is filtered by client name "jose"
- **THEN** only the records of "Tienda San José" are listed

#### Scenario: Zone filter lists only that zone's records

- **GIVEN** a default quantity in zone "Bosa" and another in zone "Soacha"
- **WHEN** the index is filtered by zone "Bosa"
- **THEN** only the "Bosa" record is listed

#### Scenario: Filters combine

- **GIVEN** default quantities exist for client "Tienda Norte" in zone
  "Bosa" and for client "Tienda Centro" in zone "Soacha"
- **WHEN** the index is filtered by client name "tienda" and zone "Bosa"
- **THEN** only the "Tienda Norte" record is listed

#### Scenario: No record matches

- **WHEN** the index is filtered by a client name no client contains
- **THEN** no rows are listed
- **AND** a message says no records match the filters

#### Scenario: Clearing the filters

- **GIVEN** the index is filtered by client name and zone
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered list is shown from its first page
- **AND** the client name box and zone select are empty

### Requirement: Default product quantity index pagination

The index SHALL be paginated, showing at most 20 matching records per page,
with controls to move to the previous and next page and to jump to a
specific page. Pagination controls SHALL NOT be shown when all matching
records fit on a single page. Moving between pages SHALL keep the active
filters, and changing a filter SHALL show the first page of the new results.

#### Scenario: Records beyond the first page are on the next page

- **GIVEN** 25 default product quantities exist and no filter is active
- **WHEN** the index is viewed
- **THEN** 20 records are listed with pagination controls
- **WHEN** the next page is opened
- **THEN** the remaining 5 records are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 default product quantities exist
- **WHEN** the index is viewed
- **THEN** all 3 are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filters

- **GIVEN** 25 default quantities in zone "Bosa" and 5 in another zone exist
- **WHEN** the index is filtered by zone "Bosa" and the next page is opened
- **THEN** the remaining 5 "Bosa" records are listed
