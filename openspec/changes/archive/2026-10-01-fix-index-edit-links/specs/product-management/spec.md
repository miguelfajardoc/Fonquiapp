## MODIFIED Requirements

### Requirement: Product index listing

The system SHALL display, for every product that matches the active filters
and falls on the current page, its name and price alongside controls to edit
or delete that product, and SHALL display a control to start creating a new
product on the same row as the filters. Products SHALL be listed in name
order. Choosing a product's edit control SHALL open that product's edit form
as a full page, regardless of the active filters or page.

#### Scenario: Index lists all products with per-row actions

- **GIVEN** at least one product exists and no filter is active
- **WHEN** the product index is viewed
- **THEN** every product on the current page has its name and price
  displayed
- **AND** each product has an edit control and a delete control

#### Scenario: Index offers a way to create a product

- **WHEN** the product index is viewed
- **THEN** a control to start creating a new product is displayed

#### Scenario: Edit control opens the edit form from a filtered list

- **GIVEN** the product index is filtered by name and lists a product
- **WHEN** that product's edit control is chosen
- **THEN** that product's edit form is shown as a full page
- **AND** no "content missing" message is shown
