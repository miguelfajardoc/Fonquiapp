## MODIFIED Requirements

### Requirement: Top-level navigation entries

The sidebar SHALL list, in order, a "Zonas" entry linking to the zone
index, a "Clientes" entry linking to the client index, a "Rutas" entry
linking to the route index, and a "Productos" entry that is not itself a
link.

#### Scenario: Zonas and Clientes navigate to their sections

- **WHEN** the "Zonas" entry is activated
- **THEN** the zone index is displayed
- **WHEN** the "Clientes" entry is activated
- **THEN** the client index is displayed

#### Scenario: Rutas navigates to the route index

- **WHEN** the "Rutas" entry is activated
- **THEN** the route index is displayed

#### Scenario: Productos entry has no direct destination

- **WHEN** the sidebar is rendered
- **THEN** the "Productos" entry is displayed
- **AND** it does not navigate to any page on its own

### Requirement: Active section highlighting

The sidebar SHALL visually distinguish the top-level entry ("Zonas",
"Clientes", or "Rutas") matching the page currently being viewed from the
other entries.

#### Scenario: Viewing the zone index highlights Zonas

- **WHEN** the zone index is displayed
- **THEN** the "Zonas" entry is shown in its highlighted (active) state
- **AND** the "Clientes" and "Rutas" entries are not

#### Scenario: Viewing the client index highlights Clientes

- **WHEN** the client index is displayed
- **THEN** the "Clientes" entry is shown in its highlighted (active) state
- **AND** the "Zonas" and "Rutas" entries are not

#### Scenario: Viewing the route index highlights Rutas

- **WHEN** the route index is displayed
- **THEN** the "Rutas" entry is shown in its highlighted (active) state
- **AND** the "Zonas" and "Clientes" entries are not
