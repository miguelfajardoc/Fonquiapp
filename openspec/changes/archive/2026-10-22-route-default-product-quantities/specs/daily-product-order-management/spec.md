## MODIFIED Requirements

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

## ADDED Requirements

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

## REMOVED Requirements

### Requirement: Route-scoped batch generation

**Reason**: Generation no longer combines per-client defaults with pending products; it uses only the route's defaults.
**Migration**: See "Route batch generation from defaults".

### Requirement: Consolidated spreadsheet download

**Reason**: The spreadsheet no longer shows pending products, and batch totals are per product, not per client.
**Migration**: See "Consolidated route spreadsheet download".
