# daily-product-order-management Specification

## Purpose

The daily product order management flow lets staff generate a route's daily
delivery totals (taken from the route's standing defaults) with one action,
review what has been generated, and download a consolidated pick sheet for
a generated batch, without needing console or database access.

## Requirements

### Requirement: Daily product order management routes

The system SHALL expose a web route to list generated daily product order
batches, a route to generate a batch for a chosen route, and a route to
download a generated batch's consolidated spreadsheet. The system SHALL NOT
expose routes to manually create, edit, or delete an individual daily
product order record.

#### Scenario: Listing, generating, and downloading are reachable

- **WHEN** a request is made to list daily product order batches, to
  generate a batch for a route, or to download a batch's consolidated
  spreadsheet
- **THEN** the corresponding action handles the request

#### Scenario: No manual create, edit, or delete routes exist

- **WHEN** a request is made to a create, edit, update, or delete route for
  an individual daily product order
- **THEN** the system reports no matching route

### Requirement: Route batch generation from defaults

The index page SHALL let a user choose a zone and then a route belonging to
that zone, and generate that route's daily product order batch. The route
choices SHALL be limited to the routes of the currently selected zone, and
changing the selected zone SHALL refresh the route choices and clear any
previously chosen route. Generating SHALL persist, for every default product
quantity of the chosen route, one `DailyProductOrder` for that product with
the default's quantity, dated with the generation date and referencing the
chosen route and its zone. Generating SHALL NOT take pending products into
account, and SHALL create no record for a product the chosen route has no
default for. The system SHALL require a route to be chosen before generating.

#### Scenario: Route choices follow the selected zone

- **GIVEN** zone A has routes "Ruta 1" and "Ruta 2" and zone B has route
  "Ruta 3"
- **WHEN** zone A is selected on the index page
- **THEN** the route choices are "Ruta 1" and "Ruta 2" only
- **WHEN** the selection is changed to zone B
- **THEN** the route choices are "Ruta 3" only and no route is chosen

#### Scenario: Generating uses the route's defaults

- **GIVEN** the chosen route has a default quantity of 20 for "Queso" and
  of 5 for "Crema"
- **WHEN** the route is generated
- **THEN** two daily product orders are created for that route: "Queso"
  with quantity 20 and "Crema" with quantity 5, each with a day equal to
  the generation date

#### Scenario: Pending products are not counted

- **GIVEN** the chosen route has a default quantity of 20 for a product,
  and a client that is a stop of that route has a pending product of
  quantity 3 for that same product in `pending` state
- **WHEN** the route is generated
- **THEN** the route's daily product order for that product has quantity 20

#### Scenario: A product with no default produces no record

- **GIVEN** the chosen route has no default quantity for a product
- **WHEN** the route is generated
- **THEN** no daily product order is created for that product

#### Scenario: Other routes' defaults are not included

- **GIVEN** "Ruta 1" has a default quantity of 20 for a product and
  "Ruta 2" of the same zone has a default quantity of 7 for that product
- **WHEN** "Ruta 1" is generated
- **THEN** "Ruta 1"'s batch contains one daily product order of quantity 20
  for that product and no order of quantity 7

#### Scenario: A route with no defaults produces an empty batch

- **GIVEN** the chosen route has no default product quantities
- **WHEN** the route is generated
- **THEN** no daily product order is created for that route

#### Scenario: Generating without choosing a zone is rejected

- **WHEN** generation is requested with no zone and no route chosen
- **THEN** no daily product order is created
- **AND** the user is shown an error and remains on the index

#### Scenario: Generating without choosing a route is rejected

- **GIVEN** a zone is selected
- **WHEN** generation is requested with no route chosen
- **THEN** no daily product order is created
- **AND** the user is shown an error and remains on the index

### Requirement: Regenerating a route on the same day replaces its batch

Generating a route for a day that already has daily product orders for that
route SHALL replace them: the existing daily product orders for that
route+day SHALL be removed before the newly computed ones are persisted,
rather than accumulating alongside them. Daily product orders of other
routes, including other routes of the same zone, SHALL NOT be affected.

#### Scenario: Regenerating replaces the previous totals

- **GIVEN** a route was generated today, producing a daily product order of
  quantity 5 for a product
- **WHEN** that route's default quantity for the product is changed and the
  same route is generated again today
- **THEN** the product's daily product order for today on that route
  reflects only the newly computed quantity, with no leftover record from
  the first generation

#### Scenario: Removing a default and regenerating drops its order

- **GIVEN** a route was generated today, producing a daily product order
  for a product
- **WHEN** that route's default quantity for the product is deleted and the
  same route is generated again today
- **THEN** that route has no daily product order for that product today

#### Scenario: Other days' batches are unaffected

- **GIVEN** a route has a daily product order from a previous day
- **WHEN** that route is generated today
- **THEN** the previous day's daily product order still exists unchanged

#### Scenario: Other routes of the same zone are unaffected

- **GIVEN** "Ruta 1" and "Ruta 2" of the same zone were both generated today
- **WHEN** "Ruta 1" is generated again today
- **THEN** today's daily product orders for "Ruta 2" still exist unchanged

### Requirement: Grouped batch listing

The index page SHALL list every day+route combination that has at least
one daily product order and matches the active table filters, grouped into
one row per combination, showing that day, the route's zone, and the
route's name, and offering a control to download that batch's consolidated
spreadsheet. Rows SHALL be ordered by the time the batch was last
generated, most recent first, so a batch that was just generated or
regenerated is listed at the top.

#### Scenario: Each generated batch appears once

- **GIVEN** a route was generated today, producing daily product orders for
  three different products
- **WHEN** the index is viewed
- **THEN** exactly one row is shown for today's generation of that route,
  showing today's date, the route's zone name, and the route's name

#### Scenario: Different batches are listed separately

- **GIVEN** two different routes of the same zone were each generated today
- **WHEN** the index is viewed
- **THEN** one row is shown for each route's batch

#### Scenario: Batches are ordered newest first

- **GIVEN** a route was generated yesterday and another route was generated
  today
- **WHEN** the index is viewed
- **THEN** today's batch is listed above yesterday's batch

#### Scenario: A just-generated batch is listed first within the same day

- **GIVEN** route "Ruta A" of zone "Bosa" was generated earlier today
- **WHEN** route "Ruta Z" of zone "Soacha" is generated afterward today and
  the index is shown
- **THEN** the "Ruta Z" batch is listed above the "Ruta A" batch

#### Scenario: Regenerating a batch moves it to the top

- **GIVEN** "Ruta A" and then "Ruta B" were generated today
- **WHEN** "Ruta A" is generated again today and the index is shown
- **THEN** the "Ruta A" batch is listed above the "Ruta B" batch

### Requirement: Consolidated route spreadsheet download

Downloading a batch's consolidated spreadsheet SHALL produce a spreadsheet
file containing: a table with one row for every client that is a stop of
the batch's route, ordered by that client's route stop position, showing
the client's name, address, and location URL as a clickable link; and,
below that table, a second table listing every product that appears in the
batch with the batch's quantity for that product. The spreadsheet SHALL NOT
show pending products. Clients of the zone that are not stops of the
batch's route SHALL NOT appear in the client table.

#### Scenario: Client rows follow the route stop order

- **GIVEN** a route has stops for client C at position 1, client A at
  position 2, and client B at position 3, and that route has a generated
  batch
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** the client table lists C, A, and B, in that order

#### Scenario: Clients that are not stops of the route are excluded

- **GIVEN** a client belongs to the batch route's zone but is not a stop of
  that route
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** that client has no row in the client table

#### Scenario: Client rows show contact info only

- **GIVEN** a generated batch's route has a stop for a client that
  currently has two pending products in `pending` state
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** the client's row shows their name, address, and location URL as
  a clickable link
- **AND** the row has no other columns, and no pending product appears
  anywhere in the spreadsheet

#### Scenario: Product totals list the batch's quantities

- **GIVEN** a generated batch has a daily product order of quantity 20 for
  "Queso" and of quantity 5 for "Crema"
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** the product totals table shows "Crema" with 5 and "Queso" with 20

#### Scenario: Product totals only include the batch's route

- **GIVEN** "Ruta 1" and "Ruta 2" of the same zone were both generated
  today, each producing a daily product order of quantity 4 for the same
  product
- **WHEN** today's "Ruta 1" consolidated spreadsheet is downloaded
- **THEN** the product totals table shows a quantity of 4 for that product

#### Scenario: The consolidated totals reflect the generated batch, not live data

- **GIVEN** a batch was generated with a daily product order of quantity 5
  for a product
- **WHEN** the route's default quantity for that product is changed
  afterward, and the batch's consolidated spreadsheet is then downloaded
- **THEN** the product totals table still shows the quantity of 5 that was
  generated, unaffected by the later change

### Requirement: Paginated batch listing

The batch listing SHALL be paginated, showing at most 20 batch rows per
page in the listing's order, with controls to move to the previous and next
page and to jump to a specific page. Pagination controls SHALL NOT be
shown when all batches fit on a single page.

#### Scenario: Batches beyond the first page are on the next page

- **GIVEN** 25 batches exist
- **WHEN** the index is viewed
- **THEN** the 20 most recent batches are listed
- **AND** pagination controls are displayed
- **WHEN** the next page is opened
- **THEN** the remaining 5 batches are listed

#### Scenario: A single page shows no pagination controls

- **GIVEN** 3 batches exist
- **WHEN** the index is viewed
- **THEN** all 3 batches are listed
- **AND** no pagination controls are displayed

### Requirement: Batch table filters

The index page SHALL offer table filters, presented separately from the
generation controls (below them and visually distinguished), consisting of
a zone select listing every zone and a route select. The route select SHALL
offer only the routes of the zone selected in the table filters, SHALL offer
no routes while no zone is selected, and SHALL be cleared when that zone
changes. The zone filter SHALL list only batches of routes in the selected
zone, and the route filter only batches of the selected route. A route that
does not belong to the selected zone SHALL be ignored. The table filters
SHALL be independent of the generation controls: changing one SHALL NOT
change the other's selection. Filters SHALL apply as soon as a select
changes, SHALL refresh only the batch list, and SHALL be reflected in the
page URL. They SHALL NOT be remembered once the user leaves the index.
Moving between pages SHALL keep the active table filters, and changing a
filter SHALL show the first page. A control next to the table filters SHALL
clear them, showing the first page of all batches with both filter selects
emptied. When no batch matches, the list SHALL show a message saying so.

#### Scenario: Zone filter lists only that zone's batches

- **GIVEN** batches exist for a route in zone "Bosa" and a route in zone
  "Soacha"
- **WHEN** the batch table is filtered by zone "Bosa"
- **THEN** only the "Bosa" batch is listed

#### Scenario: Route filter lists only that route's batches

- **GIVEN** batches exist for "Ruta 1" and "Ruta 2" of zone "Bosa"
- **WHEN** the batch table is filtered by zone "Bosa" and route "Ruta 1"
- **THEN** only the "Ruta 1" batches are listed

#### Scenario: Table route choices follow the table zone

- **GIVEN** zone "Bosa" has routes "Ruta 1" and "Ruta 2" and zone "Soacha"
  has route "Ruta 3"
- **WHEN** zone "Bosa" is selected in the table filters
- **THEN** the table route select offers "Ruta 1" and "Ruta 2" only
- **WHEN** no zone is selected in the table filters
- **THEN** the table route select offers no routes

#### Scenario: Table filters and generation controls are independent

- **GIVEN** zone "Soacha" is selected in the generation controls
- **WHEN** the batch table is filtered by zone "Bosa"
- **THEN** the generation controls still have "Soacha" selected and offer
  "Soacha"'s routes

#### Scenario: Clearing the table filters

- **GIVEN** the batch table is filtered by zone and route
- **WHEN** the clear-filters control is chosen
- **THEN** all batches are shown from the first page
- **AND** both table filter selects are empty
