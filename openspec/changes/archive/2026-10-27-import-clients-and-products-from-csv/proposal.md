## Why

Staff have their clients and products in spreadsheets, and typing them one by
one into the forms is slow and error-prone. Loading a CSV file from the client
and product indexes lets them bring in a whole list at once, while still
seeing which rows could not be loaded.

## What Changes

- New "Cargar clientes" control on the client index, to the right of
  "Crear cliente". It opens the browser's file picker for a comma-separated
  `.csv` file and loads it right after a file is chosen.
- Client CSV columns: `name`, `address`, `url`, `phone`, `zone`, `route`.
  `name`, `address` and `zone` are required per row (a client cannot exist
  without a zone). A zone or route that does not exist by name is created;
  the client is added as the last stop of its route. Coordinates are read
  only from the `url` column: full Google Maps links directly, short links
  (`maps.app.goo.gl`) by following their redirect. A client whose location
  cannot be read is still created, without a location.
- New "Cargar productos" control on the product index, to the right of
  "Crear producto". Product CSV columns: `name` and `price`, both required.
  A row whose name matches an existing product updates that product's price
  instead of failing.
- Each import processes every row; rows that fail do not stop the others.
  The result is shown as flash messages: how many were created (and, for
  products, updated), and which rows failed (by row number) and why.
- **BREAKING** Client names become unique across the whole app, ignoring
  letter case and accents. This applies to the client form too, not only to
  imports. A CSV row with an existing client's name fails as a duplicate.
- The development seeds generate distinct client names so they keep passing
  the new rule.

## Capabilities

### New Capabilities

- `client-import`: loading clients from a CSV file on the client index
  (columns, required fields, zone/route creation, location from the URL,
  per-row results).
- `product-import`: loading products from a CSV file on the product index
  (columns, required fields, price update for existing names, per-row
  results).

### Modified Capabilities

- `client-directory`: the client record requires a name not already used by
  another client, ignoring case and accents.
- `client-management`: creating or editing a client with a name already used
  by another client keeps the user on the form with an error.

## Impact

- **Models**: `Client` (name uniqueness ignoring case and accents).
- **New code**: CSV import services for clients and products, and a Google
  Maps URL coordinate reader (with short-link resolution) in `GoogleMaps`.
- **Controllers / routes**: `POST /clients/import` and
  `POST /products/import`.
- **Views**: client and product index headers, the flash partial (to list
  failed rows), `config/locales/es.yml`.
- **Dependencies**: the `csv` gem must be added to the Gemfile (Ruby 3.4
  no longer ships it as a default gem).
- **Network**: importing a client with a short link makes one outbound
  request to Google per row, limited to Google's short-link hosts, with a
  short timeout.
- **Seeds**: `db/seeds/development.rb`.
- **Tests**: model, service and request specs for both imports; client
  model and request specs for the name rule.
