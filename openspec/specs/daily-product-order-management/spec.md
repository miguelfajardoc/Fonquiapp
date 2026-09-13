# daily-product-order-management Specification

## Purpose

The daily product order management flow lets staff generate a zone's daily
delivery totals (standing defaults plus pending deliveries) with one action,
review what has been generated, and download a consolidated pick sheet for
a generated batch, without needing console or database access.

## Requirements

### Requirement: Daily product order management routes

The system SHALL expose a web route to list generated daily product order
batches, a route to generate a batch for a chosen zone, and a route to
download a generated batch's consolidated spreadsheet. The system SHALL NOT
expose routes to manually create, edit, or delete an individual daily
product order record.

#### Scenario: Listing, generating, and downloading are reachable

- **WHEN** a request is made to list daily product order batches, to
  generate a batch for a zone, or to download a batch's consolidated
  spreadsheet
- **THEN** the corresponding action handles the request

#### Scenario: No manual create, edit, or delete routes exist

- **WHEN** a request is made to a create, edit, update, or delete route for
  an individual daily product order
- **THEN** the system reports no matching route

### Requirement: Zone-scoped batch generation

The index page SHALL let a user choose a zone and generate that zone's
daily product order batch. Generating SHALL, for every client in the
chosen zone and every product, compute a total equal to that
client+product's `DefaultProductQuantity` quantity (zero if none) plus the
sum of that client+product's `PendingProduct` records currently in the
`pending` state, SHALL persist one `DailyProductOrder` per client+product
combination whose total is greater than zero (dated with the generation
date), and SHALL create no record for a combination whose total is zero.
The system SHALL require a zone to be chosen before generating.

#### Scenario: Generating combines defaults and pending quantities

- **GIVEN** a client in the chosen zone has a default quantity of 5 for a
  product and one pending product of quantity 3 for that same
  client+product in `pending` state
- **WHEN** the zone is generated
- **THEN** a daily product order for that client+product is created with
  quantity 8 and a day equal to the generation date

#### Scenario: Delivered and canceled pending products are not counted

- **GIVEN** a client in the chosen zone has a default quantity of 5 for a
  product, a pending product of quantity 3 in `delivered` state, and a
  pending product of quantity 2 in `canceled` state for that client+product
- **WHEN** the zone is generated
- **THEN** the resulting daily product order for that client+product has
  quantity 5

#### Scenario: A client+product with nothing due produces no record

- **GIVEN** a client in the chosen zone has no default quantity and no
  `pending`-state pending products for a given product
- **WHEN** the zone is generated
- **THEN** no daily product order is created for that client+product

#### Scenario: Clients and products outside the chosen zone are not included

- **GIVEN** a client belongs to a different zone than the one chosen
- **WHEN** the zone is generated
- **THEN** no daily product order is created for that other client

#### Scenario: Generating without choosing a zone is rejected

- **WHEN** generation is requested with no zone chosen
- **THEN** no daily product order is created
- **AND** the user is shown an error and remains on the index

### Requirement: Regenerating a zone on the same day replaces its batch

Generating a zone for a day that already has daily product orders for that
zone SHALL replace them: the existing daily product orders for that
zone+day SHALL be removed before the newly computed ones are persisted,
rather than accumulating alongside them.

#### Scenario: Regenerating replaces the previous totals

- **GIVEN** a zone was generated today, producing a daily product order of
  quantity 5 for a client+product
- **WHEN** that client's default quantity is changed and the same zone is
  generated again today
- **THEN** the client+product's daily product order for today reflects only
  the newly computed quantity, with no leftover record from the first
  generation

#### Scenario: Other days' batches are unaffected

- **GIVEN** a zone has a daily product order from a previous day
- **WHEN** that zone is generated today
- **THEN** the previous day's daily product order still exists unchanged

### Requirement: Grouped batch listing

The index page SHALL list every day+zone combination that has at least one
daily product order, grouped into one row per combination, showing that
day and zone, and offering a control to download that batch's consolidated
spreadsheet.

#### Scenario: Each generated batch appears once

- **GIVEN** a zone was generated today, producing daily product orders for
  three different client+product combinations
- **WHEN** the index is viewed
- **THEN** exactly one row is shown for today's generation of that zone

#### Scenario: Different batches are listed separately

- **GIVEN** two different zones were each generated today
- **WHEN** the index is viewed
- **THEN** one row is shown for each zone's batch

### Requirement: Consolidated spreadsheet download

Downloading a batch's consolidated spreadsheet SHALL produce a spreadsheet
file containing: a table with one row for every client in the batch's
zone — regardless of whether that client has a daily product order in the
batch — showing the client's name, address, and location URL as a
clickable link, followed by that client's currently-`pending`-state
pending products (if any), each shown as "<product name>: <quantity>" in
its own column; and, below that table, a second table listing every
product that appears in the batch with the batch's total quantity for that
product across all its clients.

#### Scenario: Client rows show contact info and current pending items

- **GIVEN** a generated batch includes a client with a daily product order,
  and that client currently has two pending products in `pending` state
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** the client's row shows their name, address, and location URL as
  a clickable link
- **AND** each of the two pending products appears as "<product name>:
  <quantity>" in its own column on that row

#### Scenario: A client with no current pending products has no pending columns

- **GIVEN** a generated batch includes a client with a daily product order
  and that client currently has no pending products in `pending` state
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** that client's row shows no pending product columns

#### Scenario: A client with nothing due still appears in the client table

- **GIVEN** a client belongs to the batch's zone but has no default
  quantity, no `pending`-state pending products, and no daily product
  order in the batch
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** that client still has a row, showing their name, address, and
  location URL, with no pending product columns

#### Scenario: Product totals sum across the batch's clients

- **GIVEN** a generated batch has one client with a daily product order of
  quantity 4 for a product and another client with a daily product order
  of quantity 3 for that same product
- **WHEN** the batch's consolidated spreadsheet is downloaded
- **THEN** the product totals table shows a quantity of 7 for that product

#### Scenario: The consolidated totals reflect the generated batch, not live data

- **GIVEN** a batch was generated with a daily product order of quantity 5
  for a client+product
- **WHEN** that client's default quantity is changed afterward, and the
  batch's consolidated spreadsheet is then downloaded
- **THEN** the product totals table still shows the quantity of 5 that was
  generated, unaffected by the later change
