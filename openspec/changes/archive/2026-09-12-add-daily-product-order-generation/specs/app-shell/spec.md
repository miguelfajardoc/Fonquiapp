## MODIFIED Requirements

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
