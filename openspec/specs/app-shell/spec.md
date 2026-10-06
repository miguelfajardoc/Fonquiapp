# app-shell Specification

## Purpose

The app shell is the persistent sidebar and header chrome every page renders
inside, giving staff a consistent way to navigate between sections instead
of relying on typed URLs.

## Requirements

### Requirement: Persistent sidebar and header on every page

The system SHALL render every page shown to a signed-in user inside a shared
shell consisting of a sidebar and a header. The sidebar SHALL display the
brand label "Fonquilac" above its navigation entries. The login page SHALL be
rendered without the shell.

#### Scenario: Shell wraps an existing page

- **GIVEN** a user is signed in
- **WHEN** any existing page (for example the zone index or the client
  index) is rendered
- **THEN** the sidebar and header are present around that page's content
- **AND** the sidebar shows the brand label "Fonquilac"

#### Scenario: Login page has no shell

- **WHEN** the login page is rendered
- **THEN** no sidebar or header is displayed

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

### Requirement: Productos submenu on hover

The system SHALL reveal a submenu when the pointer hovers over the
"Productos" entry, listing four entries in order: "Productos", "Default",
"Pendientes", and "Orden Diaria". Every submenu entry SHALL be a link —
"Productos" to the product index, "Default" to the default product
quantity index, "Pendientes" to the pending product index, and "Orden
Diaria" to the daily product order index.

#### Scenario: Hovering Productos reveals its submenu

- **WHEN** the pointer hovers over the "Productos" entry
- **THEN** a submenu is displayed listing "Productos", "Default",
  "Pendientes", and "Orden Diaria", in that order

#### Scenario: Productos submenu entry navigates to the product index

- **WHEN** the "Productos" submenu entry is activated
- **THEN** the product index is displayed

#### Scenario: Default submenu entry navigates to the default product quantity index

- **WHEN** the "Default" submenu entry is activated
- **THEN** the default product quantity index is displayed

#### Scenario: Pendientes submenu entry navigates to the pending product index

- **WHEN** the "Pendientes" submenu entry is activated
- **THEN** the pending product index is displayed

#### Scenario: Orden Diaria submenu entry navigates to the daily product order index

- **WHEN** the "Orden Diaria" submenu entry is activated
- **THEN** the daily product order index is displayed

#### Scenario: Submenu entries are inert

- **WHEN** the Productos submenu is displayed
- **THEN** none of its entries are inert — each one navigates to a page
  when activated

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

### Requirement: Signed-in account controls in the header

On every page inside the shell, the header SHALL show, aligned to its right
side, the signed-in user's email address, a control to open the password
change page, and a control to sign out. No avatar SHALL be displayed.

#### Scenario: Header shows the signed-in account

- **GIVEN** the user "lacteosfonquilacpc@gmail.com" is signed in
- **WHEN** any page inside the shell is rendered
- **THEN** the header shows "lacteosfonquilacpc@gmail.com"
- **AND** it shows a "Cambiar contraseña" control and a "Cerrar sesión"
  control
