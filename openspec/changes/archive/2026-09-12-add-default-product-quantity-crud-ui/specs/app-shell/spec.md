## MODIFIED Requirements

### Requirement: Productos submenu on hover

The system SHALL reveal a submenu when the pointer hovers over the
"Productos" entry, listing four entries in order: "Productos", "Default",
"Pendientes", and "Orden Diaria". The "Productos" and "Default" submenu
entries SHALL each be a link — "Productos" to the product index, and
"Default" to the default product quantity index. None of the other two
submenu entries SHALL be a link.

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

#### Scenario: Submenu entries are inert

- **WHEN** the Productos submenu is displayed
- **THEN** neither "Pendientes" nor "Orden Diaria" navigates to a page
  when activated
