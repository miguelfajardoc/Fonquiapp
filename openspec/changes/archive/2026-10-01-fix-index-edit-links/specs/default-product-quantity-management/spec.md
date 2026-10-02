## MODIFIED Requirements

### Requirement: Default product quantity index listing

The system SHALL display, for every default product quantity that matches
the active filters and falls on the current page, its client name, zone
name, product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one on the same
row as the filters. Records SHALL be listed by client name, then product
name. Choosing a record's edit control SHALL open that record's edit form as
a full page, regardless of the active filters or page.

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

#### Scenario: Edit control opens the edit form from a filtered list

- **GIVEN** the index is filtered by zone and lists a record
- **WHEN** that record's edit control is chosen
- **THEN** that record's edit form is shown as a full page
- **AND** no "content missing" message is shown
