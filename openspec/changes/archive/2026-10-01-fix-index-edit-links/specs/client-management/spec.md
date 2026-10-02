## MODIFIED Requirements

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
