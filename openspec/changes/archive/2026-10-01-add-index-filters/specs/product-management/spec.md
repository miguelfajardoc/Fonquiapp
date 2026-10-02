## MODIFIED Requirements

### Requirement: Product index listing

The system SHALL display, for every product that matches the active filters
and falls on the current page, its name and price alongside controls to edit
or delete that product, and SHALL display a control to start creating a new
product on the same row as the filters. Products SHALL be listed in name
order.

#### Scenario: Index lists all products with per-row actions

- **GIVEN** at least one product exists and no filter is active
- **WHEN** the product index is viewed
- **THEN** every product on the current page has its name and price
  displayed
- **AND** each product has an edit control and a delete control

#### Scenario: Index offers a way to create a product

- **WHEN** the product index is viewed
- **THEN** a control to start creating a new product is displayed

## ADDED Requirements

### Requirement: Product index filters

The product index SHALL offer an optional name filter that matches products
whose name contains the typed text, ignoring letter case and accents, with
typed characters matched literally (never as wildcards). The filter SHALL
apply without a separate submit action once the user stops typing, SHALL
refresh only the product list so the name box keeps focus, and SHALL be
reflected in the page URL so reloading or navigating back restores it. It
SHALL NOT be remembered once the user leaves the index. A control next to
the filter SHALL clear it, showing the first page of the unfiltered list
with the name box emptied. When no product matches, the list SHALL show a
message saying so.

#### Scenario: Name filter matches a fragment, ignoring case and accents

- **GIVEN** products named "Crema de leche" and "Queso Campesino" exist
- **WHEN** the product index is filtered by name "CREMA"
- **THEN** "Crema de leche" is listed
- **AND** "Queso Campesino" is not listed

#### Scenario: Name filter ignores accents

- **GIVEN** a product named "Queso Añejo" exists
- **WHEN** the product index is filtered by name "anejo"
- **THEN** "Queso Añejo" is listed

#### Scenario: No product matches

- **WHEN** the product index is filtered by a name no product contains
- **THEN** no product rows are listed
- **AND** a message says no products match the filters

#### Scenario: Clearing the filter

- **GIVEN** the product index is filtered by name
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered product list is shown from its first page
- **AND** the name box is empty

### Requirement: Product index pagination

The product index SHALL be paginated, showing at most 20 matching products
per page, with controls to move to the previous and next page and to jump to
a specific page. Pagination controls SHALL NOT be shown when all matching
products fit on a single page. Moving between pages SHALL keep the active
filter, and changing the filter SHALL show the first page of the new
results.

#### Scenario: Products beyond the first page are on the next page

- **GIVEN** 25 products exist and no filter is active
- **WHEN** the product index is viewed
- **THEN** the first 20 products in name order are listed with pagination
  controls
- **WHEN** the next page is opened
- **THEN** the remaining 5 products are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 products exist
- **WHEN** the product index is viewed
- **THEN** all 3 products are listed
- **AND** no pagination controls are displayed

#### Scenario: Page links keep the active filter

- **GIVEN** 25 products whose names contain "queso" and 5 other products
  exist
- **WHEN** the product index is filtered by name "queso" and the next page
  is opened
- **THEN** the remaining 5 "queso" products are listed
