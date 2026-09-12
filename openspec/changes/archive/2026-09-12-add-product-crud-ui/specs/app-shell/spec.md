## MODIFIED Requirements

### Requirement: Productos submenu on hover

The system SHALL reveal a submenu when the pointer hovers over the
"Productos" entry, listing four entries in order: "Productos", "Default",
"Pendientes", and "Orden Diaria". The "Productos" submenu entry SHALL be a
link to the product index. None of the other three submenu entries SHALL
be a link.

#### Scenario: Hovering Productos reveals its submenu

- **WHEN** the pointer hovers over the "Productos" entry
- **THEN** a submenu is displayed listing "Productos", "Default",
  "Pendientes", and "Orden Diaria", in that order

#### Scenario: Productos submenu entry navigates to the product index

- **WHEN** the "Productos" submenu entry is activated
- **THEN** the product index is displayed

#### Scenario: Submenu entries are inert

- **WHEN** the Productos submenu is displayed
- **THEN** none of "Default", "Pendientes", or "Orden Diaria" navigates to
  a page when activated
