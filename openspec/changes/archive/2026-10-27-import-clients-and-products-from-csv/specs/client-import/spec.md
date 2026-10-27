## Purpose

Client import lets staff load many clients at once from a comma-separated CSV
file on the client index, creating missing zones and routes on the way and
reporting which rows could not be loaded.

## ADDED Requirements

### Requirement: Client import control

The client index SHALL display a "Cargar clientes" control immediately to the
right of the "Crear cliente" control. Choosing it SHALL open the browser's
standard file picker limited to `.csv` files, and choosing a file SHALL start
the import right away, without a separate submit step. When the import
finishes, the user SHALL be returned to the client index with the result
shown as flash messages.

#### Scenario: The control sits to the right of the create control

- **WHEN** the client index is viewed
- **THEN** a "Cargar clientes" control is displayed immediately to the right
  of the "Crear cliente" control

#### Scenario: Choosing a file starts the import

- **GIVEN** the client index is open
- **WHEN** "Cargar clientes" is chosen and a `.csv` file is picked in the
  file picker
- **THEN** the file is imported without any further action
- **AND** the client index is shown again with the import result

### Requirement: Client CSV file format

The system SHALL accept a comma-separated file whose first row is a header
naming the columns `name`, `address`, `url`, `phone`, `zone`, and `route`.
Headers SHALL be matched ignoring letter case and surrounding spaces, and
columns MAY appear in any order. The `url`, `phone`, and `route` columns MAY
be missing from the file. The file SHALL be read as UTF-8 (a leading
byte-order mark is ignored), falling back to Windows-1252 when it is not
valid UTF-8. Blank lines SHALL be ignored. When no file is chosen, the file
cannot be parsed as CSV, or its header lacks `name`, `address`, or `zone`,
the system SHALL create nothing and SHALL show an error saying why.

#### Scenario: Headers match regardless of case, spaces and order

- **GIVEN** a file whose header is ` Zone ,NAME,Address`
- **WHEN** it is imported with one valid row
- **THEN** that client is created with the zone, name and address from the
  matching columns

#### Scenario: A file without a required column is rejected

- **GIVEN** a file whose header has `name` and `address` but no `zone`
- **WHEN** it is imported
- **THEN** no client, zone or route is created
- **AND** an error says the `zone` column is missing

#### Scenario: A file exported by Excel with accents is read correctly

- **GIVEN** a UTF-8 file with a byte-order mark, or a Windows-1252 file,
  containing a client named "Tienda San José"
- **WHEN** it is imported
- **THEN** the client is created with the name "Tienda San José"

#### Scenario: Importing without choosing a file

- **WHEN** an import is submitted with no file
- **THEN** nothing is created
- **AND** an error asks the user to choose a CSV file

### Requirement: Creating clients from rows

For each data row, the system SHALL create one client from its `name`,
`address`, `phone`, and `zone` values, trimmed of surrounding spaces.
`name`, `address`, and `zone` SHALL be required for every row; `url`,
`phone`, and `route` SHALL be optional. The zone SHALL be the existing zone
whose name matches the `zone` value ignoring letter case and accents, or a
new zone with that name when none matches. When `route` has a value, the
route SHALL be the existing route of that zone whose name matches it
ignoring letter case and accents, or a new route of that zone with that name
when none matches, and the client SHALL be added as that route's last stop.
A zone or route SHALL be created only when its row's client is created.

#### Scenario: A row with an existing zone and route

- **GIVEN** zone "Bosa" exists with route "Ruta 1", which has two stops
- **WHEN** a file with the row `Tienda Norte,Calle 1,,3001234567,bosa,ruta 1`
  is imported
- **THEN** client "Tienda Norte" is created in zone "Bosa" with address
  "Calle 1" and phone "3001234567"
- **AND** it is the third stop of "Ruta 1"
- **AND** no new zone or route is created

#### Scenario: A row with a new zone and route

- **GIVEN** no zone named "Kennedy" exists
- **WHEN** a file with a valid row for zone "Kennedy" and route "Ruta 5" is
  imported
- **THEN** zone "Kennedy" is created, with route "Ruta 5"
- **AND** the client is created in "Kennedy" as the first stop of "Ruta 5"

#### Scenario: Two rows with the same new zone create it once

- **GIVEN** no zone named "Kennedy" exists
- **WHEN** a file with two valid rows for zone "Kennedy" is imported
- **THEN** exactly one zone named "Kennedy" exists, with both clients

#### Scenario: A row without a route

- **WHEN** a file with a valid row whose `route` is blank is imported
- **THEN** the client is created and is a stop of no route

#### Scenario: A row missing a required value fails

- **WHEN** a file with a row whose `name`, `address`, or `zone` is blank is
  imported
- **THEN** no client is created for that row
- **AND** no zone or route is created for that row
- **AND** the row is reported as failed, naming the missing value

#### Scenario: A row with a duplicate client name fails

- **GIVEN** a client named "Tienda San José" exists
- **WHEN** a file with a row named "tienda san jose" is imported
- **THEN** no client is created for that row
- **AND** the row is reported as failed because the name already exists

### Requirement: Client location from the URL

The system SHALL take a row's client location only from its `url` value,
never from the address. When the url is a full Google Maps link containing
coordinates (as `@<lat>,<lng>`, `!3d<lat>!4d<lng>`, or a `query`, `q`, or
`ll` parameter of the form `<lat>,<lng>`), the client SHALL be created with
those coordinates. When the url is a Google Maps short link
(`maps.app.goo.gl` or `goo.gl/maps`), the system SHALL follow its redirects
(at most three, each with a short timeout) to the full link and read the
coordinates from it. The system SHALL NOT make requests to any other host.
Coordinates outside the valid latitude and longitude ranges SHALL be
ignored. When no coordinates can be read, or the short link cannot be
followed, the client SHALL still be created, without a location, and the row
SHALL NOT count as failed. The url value itself SHALL NOT be stored: the
client's url is derived from its location or address as for any other
client.

#### Scenario: Coordinates from a full link

- **WHEN** a file with a valid row whose url is
  `https://www.google.com/maps/place/Tienda/@4.7110,-74.0721,17z` is
  imported
- **THEN** the client is created with latitude 4.711 and longitude -74.0721

#### Scenario: Coordinates from a short link

- **GIVEN** the short link `https://maps.app.goo.gl/AbC123` redirects to a
  full link containing `!3d4.65!4d-74.1`
- **WHEN** a file with a valid row whose url is that short link is imported
- **THEN** the client is created with latitude 4.65 and longitude -74.1

#### Scenario: An unreadable link leaves the client without a location

- **WHEN** a file with a valid row whose url is a link with no coordinates,
  or a short link that cannot be followed, is imported
- **THEN** the client is created without a location
- **AND** the row is not reported as failed

#### Scenario: A row without a url has no location

- **WHEN** a file with a valid row whose url is blank is imported
- **THEN** the client is created without a location, even though it has an
  address

#### Scenario: Links to other hosts are not requested

- **WHEN** a file with a valid row whose url is `https://example.com/x` is
  imported
- **THEN** no request is made to `example.com`
- **AND** the client is created without a location

### Requirement: Client import result

Every row SHALL be processed independently: a failed row SHALL NOT prevent
the rows before or after it from being created. After the import, the system
SHALL show a notice with the number of clients created, and, when any row
failed, an alert listing each failed row by its line number in the file (the
header is line 1) with the reason it failed. The alert SHALL list at most 20
failed rows and SHALL say how many more failed beyond those.

#### Scenario: Failed rows do not stop the others

- **GIVEN** a file with five data rows where the rows on lines 3 and 5 have
  no name
- **WHEN** it is imported
- **THEN** the three valid clients are created
- **AND** a notice says 3 clients were created
- **AND** an alert lists line 3 and line 5, each with its reason

#### Scenario: All rows valid

- **WHEN** a file with only valid rows is imported
- **THEN** a notice says how many clients were created
- **AND** no alert is shown

#### Scenario: Many failed rows are summarized

- **GIVEN** a file with 25 rows that all fail
- **WHEN** it is imported
- **THEN** the alert lists the first 20 failed rows
- **AND** it says 5 more rows failed
