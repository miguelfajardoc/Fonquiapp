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

### Requirement: Sidebar top-level entries

The sidebar SHALL list, in order, a "Zonas" entry linking to the zone index,
a "Clientes" entry linking to the client index, a "Rutas" entry that is not
itself a link, a "Productos" entry linking to the product index, a
"Pendientes" entry linking to the pending product index, and an "Orden
Diaria" entry linking to the daily product order index. "Productos",
"Pendientes" and "Orden Diaria" SHALL NOT reveal any submenu.

#### Scenario: Zonas and Clientes navigate to their sections

- **WHEN** the "Zonas" entry is activated
- **THEN** the zone index is displayed
- **WHEN** the "Clientes" entry is activated
- **THEN** the client index is displayed

#### Scenario: Entries are listed in order

- **WHEN** the sidebar is rendered
- **THEN** its top-level entries are "Zonas", "Clientes", "Rutas",
  "Productos", "Pendientes", and "Orden Diaria", in that order

#### Scenario: Rutas entry has no direct destination

- **WHEN** the sidebar is rendered
- **THEN** the "Rutas" entry is displayed
- **AND** it does not navigate to any page on its own

#### Scenario: Productos navigates to the product index

- **WHEN** the "Productos" entry is activated
- **THEN** the product index is displayed

#### Scenario: Pendientes navigates to the pending product index

- **WHEN** the "Pendientes" entry is activated
- **THEN** the pending product index is displayed

#### Scenario: Orden Diaria navigates to the daily product order index

- **WHEN** the "Orden Diaria" entry is activated
- **THEN** the daily product order index is displayed

#### Scenario: Productos has no submenu

- **WHEN** the pointer hovers over the "Productos" entry
- **THEN** no submenu is displayed

### Requirement: Rutas submenu on hover

The system SHALL reveal a submenu when the pointer hovers over the "Rutas"
entry, listing two entries in order: "Rutas" and "Default". Every submenu
entry SHALL be a link: "Rutas" to the route index and "Default" to the
default product quantity index.

#### Scenario: Hovering Rutas reveals its submenu

- **WHEN** the pointer hovers over the "Rutas" entry
- **THEN** a submenu is displayed listing "Rutas" and "Default", in that order

#### Scenario: Rutas submenu entry navigates to the route index

- **WHEN** the "Rutas" submenu entry is activated
- **THEN** the route index is displayed

#### Scenario: Default submenu entry navigates to the default product quantity index

- **WHEN** the "Default" submenu entry is activated
- **THEN** the default product quantity index is displayed

### Requirement: Active section highlighting

The sidebar SHALL visually distinguish the top-level entry matching the page
currently being viewed from the other entries. The "Rutas" entry SHALL be
highlighted on both the route index and the default product quantity pages.

#### Scenario: Viewing the zone index highlights Zonas

- **WHEN** the zone index is displayed
- **THEN** the "Zonas" entry is shown in its highlighted (active) state
- **AND** no other top-level entry is

#### Scenario: Viewing the client index highlights Clientes

- **WHEN** the client index is displayed
- **THEN** the "Clientes" entry is shown in its highlighted (active) state
- **AND** no other top-level entry is

#### Scenario: Viewing the route index highlights Rutas

- **WHEN** the route index is displayed
- **THEN** the "Rutas" entry is shown in its highlighted (active) state
- **AND** no other top-level entry is

#### Scenario: Viewing the default product quantity index highlights Rutas

- **WHEN** the default product quantity index is displayed
- **THEN** the "Rutas" entry is shown in its highlighted (active) state
- **AND** no other top-level entry is

#### Scenario: Viewing the product, pending product or daily order index highlights its entry

- **WHEN** the product index, the pending product index, or the daily
  product order index is displayed
- **THEN** the matching entry ("Productos", "Pendientes", or "Orden
  Diaria") is shown in its highlighted (active) state
- **AND** no other top-level entry is

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
