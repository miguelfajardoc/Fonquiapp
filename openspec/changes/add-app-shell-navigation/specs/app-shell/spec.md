## Purpose

The app shell is the persistent sidebar and header chrome every page renders
inside, giving staff a consistent way to navigate between sections instead
of relying on typed URLs.

## ADDED Requirements

### Requirement: Persistent sidebar and header on every page

The system SHALL render every page inside a shared shell consisting of a
sidebar and a header. The sidebar SHALL display the brand label "Fonquilac"
above its navigation entries.

#### Scenario: Shell wraps an existing page

- **WHEN** any existing page (for example the zone index or the client
  index) is rendered
- **THEN** the sidebar and header are present around that page's content
- **AND** the sidebar shows the brand label "Fonquilac"

### Requirement: Top-level navigation entries

The sidebar SHALL list, in order, a "Zonas" entry linking to the zone
index, a "Clientes" entry linking to the client index, and a "Productos"
entry that is not itself a link.

#### Scenario: Zonas and Clientes navigate to their sections

- **WHEN** the "Zonas" entry is activated
- **THEN** the zone index is displayed
- **WHEN** the "Clientes" entry is activated
- **THEN** the client index is displayed

#### Scenario: Productos entry has no direct destination

- **WHEN** the sidebar is rendered
- **THEN** the "Productos" entry is displayed
- **AND** it does not navigate to any page on its own

### Requirement: Productos submenu on hover

The system SHALL reveal a submenu when the pointer hovers over the
"Productos" entry, listing four entries in order: "Productos", "Default",
"Pendientes", and "Orden Diaria". None of these four submenu entries SHALL
be a link.

#### Scenario: Hovering Productos reveals its submenu

- **WHEN** the pointer hovers over the "Productos" entry
- **THEN** a submenu is displayed listing "Productos", "Default",
  "Pendientes", and "Orden Diaria", in that order

#### Scenario: Submenu entries are inert

- **WHEN** the Productos submenu is displayed
- **THEN** none of "Productos", "Default", "Pendientes", or "Orden Diaria"
  navigates to a page when activated

### Requirement: Active section highlighting

The sidebar SHALL visually distinguish the top-level entry ("Zonas" or
"Clientes") matching the page currently being viewed from the other
entries.

#### Scenario: Viewing the zone index highlights Zonas

- **WHEN** the zone index is displayed
- **THEN** the "Zonas" entry is shown in its highlighted (active) state
- **AND** the "Clientes" entry is not

#### Scenario: Viewing the client index highlights Clientes

- **WHEN** the client index is displayed
- **THEN** the "Clientes" entry is shown in its highlighted (active) state
- **AND** the "Zonas" entry is not

### Requirement: No user identity displayed

Since no user or session model exists yet, the shell SHALL NOT display any
user name, avatar, or account control in the sidebar or header.

#### Scenario: Shell renders without a user identity

- **WHEN** any page is rendered inside the shell
- **THEN** no user name, avatar, or account control is displayed in the
  sidebar or header
