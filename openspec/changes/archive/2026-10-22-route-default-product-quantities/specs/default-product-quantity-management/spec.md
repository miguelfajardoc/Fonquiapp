## MODIFIED Requirements

### Requirement: Default product quantity index listing

The system SHALL display, for every default product quantity that matches
the active filters and falls on the current page, its zone name, route
name, product name, and quantity, alongside controls to edit or delete that
record, and SHALL display a control to start creating a new one on the same
row as the filters. Records SHALL be listed by zone name, then route name,
then product name. Choosing a record's edit control SHALL open that
record's edit modal over the index, regardless of the active filters or
page, without leaving the index.

#### Scenario: Index lists all records with per-row actions

- **GIVEN** at least one default product quantity exists and no filter is
  active
- **WHEN** the index is viewed
- **THEN** every record on the current page has its zone name, route name,
  product name, and quantity displayed
- **AND** each record has an edit control and a delete control

#### Scenario: Records are ordered by zone, route, then product

- **GIVEN** zone "Bosa" has route "Ruta 2" with a default for "Queso" and
  route "Ruta 1" with defaults for "Queso" and "Crema", and zone "Soacha"
  has a route with a default for "Arequipe"
- **WHEN** the index is viewed with no filter
- **THEN** the records are listed as "Bosa / Ruta 1 / Crema", "Bosa /
  Ruta 1 / Queso", "Bosa / Ruta 2 / Queso", then the "Soacha" record

#### Scenario: Index offers a way to create a record

- **WHEN** the index is viewed
- **THEN** a control to start creating a new default product quantity is
  displayed

#### Scenario: Edit control opens the edit form from a filtered list

- **GIVEN** the index is filtered by zone and lists a record
- **WHEN** that record's edit control is chosen
- **THEN** that record's edit modal opens over the filtered index
- **AND** the index, its filters, and its current page stay as they were
- **AND** no "content missing" message is shown

### Requirement: Default product quantity deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with
a cancel option and a confirm option, before deleting a default product
quantity. The system SHALL NOT delete the record unless the confirm option
is chosen. Confirming SHALL delete the record and remove its row from the
page it was deleted from (the index or the route's default list on the
creation page) without a full page reload.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a default product quantity exists
- **WHEN** the delete control is chosen for that record
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the record still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the record

- **GIVEN** a default product quantity exists and its delete confirmation
  prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the record still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion removes the record

- **GIVEN** a default product quantity exists
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the record is deleted
- **AND** its row is removed from the page without a full page reload

## ADDED Requirements

### Requirement: Route default quantity creation

The system SHALL let a user submit a zone, a route (belonging to that
zone), a product, and a quantity to create a new default product quantity.
After a successful submission the user SHALL stay on the creation page: the
new record SHALL appear in that route's default list below the form, and
the form SHALL be reset for the next entry, keeping the same zone and route
and clearing the product and quantity. When the submission is invalid (per
the record's existing validation and uniqueness rules), the system SHALL
keep the user on the creation page with the invalid input and an error, and
SHALL NOT change the route's list. The user SHALL be able to cancel back to
the index without creating a record.

#### Scenario: Creating a record with valid data

- **GIVEN** a zone, a route in that zone, and a product exist, with no
  default product quantity yet for that route+product
- **WHEN** the new-record form is submitted with that zone, route, product,
  and a quantity greater than zero
- **THEN** the record is created
- **AND** the user stays on the creation page, where the new record appears
  in the route's default list
- **AND** the form keeps the same zone and route selected with the product
  and quantity cleared

#### Scenario: Creating several records for the same route in a row

- **GIVEN** a zone, a route in that zone, and two products exist
- **WHEN** the form is submitted for the first product and then, without
  choosing the route again, for the second product
- **THEN** both records are created for that route
- **AND** both appear in the route's default list on the creation page

#### Scenario: Creating a record for a combination that already has one

- **GIVEN** a default product quantity already exists for a route+product
- **WHEN** the new-record form is submitted for that same route+product
- **THEN** no record is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Creating a record with a zero, negative or non-integer quantity

- **WHEN** the new-record form is submitted with a quantity of 0, a
  negative quantity, or a non-integer quantity
- **THEN** no record is created
- **AND** the creation form is shown again with a validation error

#### Scenario: Canceling creation

- **WHEN** cancel is chosen on the new-record form
- **THEN** the user is returned to the index
- **AND** no record is created

### Requirement: Route default quantity editing

The system SHALL let a user edit an existing default product quantity in a
modal, opened from the index or from the route's default list on the
creation page, without leaving that page. The modal SHALL show the record's
zone and route as fixed values that cannot be changed, and SHALL let the
user change only the product and the quantity. On a successful submission
the modal SHALL close and the record's row SHALL be updated in place on the
page it was opened from. On an invalid submission (per the record's
existing validation and uniqueness rules) the modal SHALL stay open with
the invalid input and an error, and the record SHALL NOT change. Cancelling
SHALL close the modal without changing the record.

#### Scenario: Updating a record with valid data

- **GIVEN** a default product quantity exists
- **WHEN** its edit modal is submitted with a product and a quantity greater
  than zero, forming a combination not already used by another record of
  the same route
- **THEN** the record is updated
- **AND** the modal closes and the record's row shows the updated product
  and quantity without a page reload

#### Scenario: The modal does not allow changing zone or route

- **GIVEN** a default product quantity exists
- **WHEN** its edit modal is opened
- **THEN** its zone and route are shown but cannot be changed
- **AND** the product and quantity can be changed

#### Scenario: Updating a record into a combination already used by another

- **GIVEN** two default product quantities exist for the same route with
  different products
- **WHEN** one record's edit modal is submitted with the other record's
  product
- **THEN** the record is not changed
- **AND** the modal stays open with a validation error

#### Scenario: Updating a record with a quantity of zero

- **GIVEN** a default product quantity exists
- **WHEN** its edit modal is submitted with a quantity of 0
- **THEN** the record is not changed
- **AND** the modal stays open with a validation error

#### Scenario: Canceling editing

- **GIVEN** a default product quantity's edit modal is open
- **WHEN** cancel is chosen
- **THEN** the modal closes
- **AND** the record is not changed

### Requirement: Default product quantity zone and route filters

The index SHALL offer two optional, combinable filters: a zone select
listing every zone and a route select. The route select SHALL offer only
the routes of the selected zone, SHALL offer no routes while no zone is
selected, and SHALL be cleared when the zone changes. The zone filter SHALL
match records whose route belongs to the selected zone, and the route
filter SHALL match records of the selected route; a route that does not
belong to the selected zone SHALL be ignored. A blank filter SHALL NOT
restrict the list. Filters SHALL apply as soon as a select changes, SHALL
refresh only the list, and SHALL be reflected in the page URL. They SHALL
NOT be remembered once the user leaves the index. A control next to the
filters SHALL clear them all, showing the first page of the unfiltered list
with every filter control emptied. When no record matches, the list SHALL
show a message saying so.

#### Scenario: Zone filter lists only that zone's records

- **GIVEN** a default quantity of a route in zone "Bosa" and another of a
  route in zone "Soacha"
- **WHEN** the index is filtered by zone "Bosa"
- **THEN** only the "Bosa" record is listed

#### Scenario: Route filter lists only that route's records

- **GIVEN** default quantities exist for "Ruta 1" and "Ruta 2" of zone
  "Bosa"
- **WHEN** the index is filtered by zone "Bosa" and route "Ruta 1"
- **THEN** only the "Ruta 1" records are listed

#### Scenario: Route choices follow the selected zone

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha"
  has route "Ruta 3"
- **WHEN** zone "Bosa" is selected in the filters
- **THEN** the route select offers "Ruta 1" and "Ruta 2" only
- **WHEN** no zone is selected
- **THEN** the route select offers no routes

#### Scenario: No record matches

- **GIVEN** a zone whose routes have no default quantities
- **WHEN** the index is filtered by that zone
- **THEN** no rows are listed
- **AND** a message says no records match the filters

#### Scenario: Clearing the filters

- **GIVEN** the index is filtered by zone and route
- **WHEN** the clear-filters control is chosen
- **THEN** the unfiltered list is shown from its first page
- **AND** the zone and route selects are empty

### Requirement: Zone-scoped route selection

The creation form SHALL let a user choose a zone, then choose a route
belonging only to that zone. Changing the chosen zone SHALL update the
available routes to that zone's routes and SHALL clear any previously
chosen route.

#### Scenario: Route choices are limited to the chosen zone

- **GIVEN** routes exist in two different zones
- **WHEN** a zone is chosen on the creation form
- **THEN** only routes belonging to that zone can be chosen as the route

#### Scenario: Changing the zone clears the chosen route

- **GIVEN** a zone is chosen and a route belonging to it has been chosen
- **WHEN** a different zone is chosen
- **THEN** the route choice is cleared
- **AND** only the new zone's routes can be chosen as the route

### Requirement: Route default list on the creation page

The creation page SHALL show, below the form, the default product
quantities of the currently chosen route, under a heading naming that
route. Each entry SHALL show the product name and quantity, with an edit
control (opening the edit modal) and a delete control (with confirmation).
Entries SHALL be listed by product name. When the chosen route has none, a
message SHALL say so. When no route is chosen, a prompt to choose a route
SHALL be shown instead of a list. The list SHALL refresh whenever the route
choice changes, and SHALL return to the choose-a-route prompt when the zone
changes (because that clears the route).

#### Scenario: Choosing a route shows its defaults

- **GIVEN** route "Ruta 1" has default quantities for "Queso" (20) and
  "Crema" (5), and another route has a default for "Suero"
- **WHEN** "Ruta 1" is chosen on the creation page
- **THEN** a heading naming "Ruta 1" is shown
- **AND** "Crema" (5) and "Queso" (20) are listed, in that order, each with
  an edit and a delete control
- **AND** "Suero" is not listed

#### Scenario: No route chosen

- **WHEN** the creation page is opened without choosing a route
- **THEN** a prompt to choose a route is shown and no list is displayed

#### Scenario: Chosen route has no defaults

- **GIVEN** a route with no default product quantities
- **WHEN** that route is chosen on the creation page
- **THEN** a message says the route has no defaults

#### Scenario: Changing the zone resets the list

- **GIVEN** a route is chosen and its defaults are listed
- **WHEN** a different zone is chosen
- **THEN** the list is replaced by the prompt to choose a route

## REMOVED Requirements

### Requirement: Default product quantity creation

**Reason**: Creation is now scoped by zone → route instead of zone → client, and requires a quantity greater than zero.
**Migration**: See "Route default quantity creation".

### Requirement: Default product quantity editing

**Reason**: The modal now fixes zone and route instead of zone and client, and requires a quantity greater than zero.
**Migration**: See "Route default quantity editing".

### Requirement: Default product quantity index filters

**Reason**: The client name filter is replaced by a route filter that follows the selected zone.
**Migration**: See "Default product quantity zone and route filters".

### Requirement: Zone-scoped client selection

**Reason**: Default quantities no longer belong to a client; they belong to
a route.
**Migration**: Use the zone → route selection ("Zone-scoped route
selection").

### Requirement: Client default list on the creation page

**Reason**: Default quantities no longer belong to a client; the creation
page lists the chosen route's defaults instead.
**Migration**: See "Route default list on the creation page".
