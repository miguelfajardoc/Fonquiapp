## Purpose

The product management flow is the web interface staff use to list,
create, edit, and remove products in the catalog, without needing console
or database access, while respecting the product's existing validation and
delete-restriction rules.

## ADDED Requirements

### Requirement: Product management routes

The system SHALL expose web routes to list products, start and submit
product creation, start and submit product editing, and delete a product.
The system SHALL NOT expose a dedicated detail ("show") route for a single
product.

#### Scenario: Listing, creating, editing, and deleting are reachable

- **WHEN** a request is made to list products, to the new-product form, to
  create a product, to the edit-product form, to update a product, or to
  delete a product
- **THEN** the corresponding action handles the request

#### Scenario: No detail route exists

- **WHEN** a request is made to a single product's detail ("show") route
- **THEN** the system reports no matching route

### Requirement: Product index listing

The system SHALL display every product's name and price alongside controls
to edit or delete that product, and SHALL display a control to start
creating a new product.

#### Scenario: Index lists all products with per-row actions

- **GIVEN** at least one product exists
- **WHEN** the product index is viewed
- **THEN** every existing product's name and price are displayed
- **AND** each product has an edit control and a delete control

#### Scenario: Index offers a way to create a product

- **WHEN** the product index is viewed
- **THEN** a control to start creating a new product is displayed

### Requirement: Product creation

The system SHALL let a user submit a name and a price to create a new
product, SHALL keep the user on the creation form with the invalid input
and an error when the submission is invalid (per the product's existing
validation rules), and SHALL let the user cancel back to the product index
without creating a product.

#### Scenario: Creating a product with valid data

- **WHEN** the new-product form is submitted with a non-blank, unused name
  and a valid, non-negative price
- **THEN** the product is created
- **AND** the user is returned to the product index, where the new product
  appears

#### Scenario: Creating a product with invalid data

- **GIVEN** a product named "Agua 500ml" already exists
- **WHEN** the new-product form is submitted with a blank name, with
  "Agua 500ml", with a blank price, or with a negative price
- **THEN** no product is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Canceling product creation

- **WHEN** cancel is chosen on the new-product form
- **THEN** the user is returned to the product index
- **AND** no product is created

### Requirement: Product editing

The system SHALL let a user submit a new name and/or price to update an
existing product, SHALL keep the user on the edit form with the invalid
input and an error when the submission is invalid (per the product's
existing validation rules), and SHALL let the user cancel back to the
product index without changing the product.

#### Scenario: Updating a product with valid data

- **GIVEN** a product exists
- **WHEN** the edit form for that product is submitted with a non-blank,
  unused name and a valid, non-negative price
- **THEN** the product's name and price are updated
- **AND** the user is returned to the product index, where the updated
  values appear

#### Scenario: Updating a product with invalid data

- **GIVEN** two products exist, one named "Agua 500ml" and one named
  "Gaseosa 1.5L"
- **WHEN** the edit form for "Gaseosa 1.5L" is submitted with a blank
  name, with "Agua 500ml", with a blank price, or with a negative price
- **THEN** the product named "Gaseosa 1.5L" is not changed
- **AND** the edit form is shown again with a validation error

#### Scenario: Canceling product editing

- **GIVEN** a product exists
- **WHEN** cancel is chosen on that product's edit form
- **THEN** the user is returned to the product index
- **AND** the product is not changed

### Requirement: Product deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with
a cancel option and a confirm option, before deleting a product. The
system SHALL NOT delete the product unless the confirm option is chosen.
When the confirm option is chosen for a product that cannot be deleted
because it is still referenced by other records, the system SHALL leave
the product in place and SHALL report that the deletion could not be
completed.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a product exists
- **WHEN** the delete control is chosen for that product
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the product still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the product

- **GIVEN** a product exists and its delete confirmation prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the product still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion of an unreferenced product

- **GIVEN** a product exists with no pending products, default quantities,
  or daily orders referencing it
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the product is deleted
- **AND** it no longer appears on the product index

#### Scenario: Confirming deletion of a product still in use

- **GIVEN** a product exists that is referenced by at least one pending
  product, default quantity, or daily order record
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the product is not deleted
- **AND** the product index reports that the product could not be deleted
