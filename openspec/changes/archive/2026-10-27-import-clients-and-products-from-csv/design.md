## Context

See proposal.md for the motivation. Current state that shapes the approach:

- `Client` requires a name and a zone; `before_save :derive_url` always
  rebuilds `url` from the coordinates (or the address), so a typed url is
  never stored. Names are not unique today.
- `Product` already has a unique index on `name` (exact match) and a
  non-negative decimal `price` with two decimals.
- `Route` names are unique per zone; `RouteStop` uses `acts_as_list`, so
  creating a stop without a position appends it at the bottom.
- The `unaccent` extension is enabled; `Filterable.where_unaccent_contains`
  already does accent-insensitive matching.
- `GoogleMaps` is the single module that knows about Google Maps; the app
  has no server-side HTTP client and no WebMock in the test suite.
- The index headers render the filter form and the create link as siblings
  inside one `flex justify-between` row. The flash partial renders each
  message as plain text.
- Ruby 3.4: `csv` is a bundled gem, so it must be declared in the Gemfile.

## Goals / Non-Goals

**Goals:**
- One shared reader for both imports (encoding, header check, line numbers),
  with small per-model row handlers.
- Per-row atomicity: a client row's zone, route, client and stop are created
  together or not at all.
- No new JavaScript and no new HTTP dependency.

**Non-Goals:**
- Geocoding addresses on the server (explicitly declined).
- Background jobs or progress bars; files are expected to be small (tens or
  hundreds of rows), so the import runs inside the request.
- Updating existing clients from the CSV; a matching name is a failure.
- A database-level unique index on client names (see Decision 1).

## Decisions

### 1. Client name uniqueness as a model validation

`Client` gets a custom validation: the name is taken when another client
exists with `lower(unaccent(name)) = lower(unaccent(?))` for the stripped
name. The error is added to `:name` as `:taken` ("ya está en uso").

*Alternative:* a unique expression index. Rejected: `unaccent` is not
`IMMUTABLE` in PostgreSQL, so it cannot be indexed without a wrapper
function, and two staff members creating the same name at the same instant
is not a real risk here. No migration is needed. Existing duplicates (only
possible in development data) would only block saving those records until
renamed; `db:reset` produces distinct names after Decision 7.

### 2. Shared CSV reading in `CsvImport`

`app/services/csv_import.rb` holds the common part:
- Reads the uploaded file (rejecting a missing file and files over 2 MB).
- Decodes: strip a UTF-8 BOM; if the bytes are not valid UTF-8, transcode
  from Windows-1252.
- Parses with `CSV.new(text, headers: true, skip_blanks: true,
  header_converters: ->(h) { h.to_s.strip.downcase })`.
- Checks required headers and raises `CsvImport::InvalidFile` with a
  translated message naming the missing column(s); `CSV::MalformedCSVError`
  is turned into the same error.
- Iterates rows yielding `(row, line)` where `line` is `csv.lineno`, which
  counts physical lines, so it matches what the user sees in a spreadsheet
  even with blank lines.
- Collects a `Result` struct: `created`, `updated`, `failures` (array of
  `[line, message]`).

`ClientCsvImport` and `ProductCsvImport` subclass it, declare their required
headers and implement `import_row(row)`, which raises
`CsvImport::RowError` (or lets `ActiveRecord::RecordInvalid` escape) to mark
a failure. Failure messages are the record's `full_messages.to_sentence`, or
"falta <columna>" for blank required values.

### 3. Client rows run in their own transaction

```ruby
Client.transaction do
  zone  = find_or_create_zone!(row["zone"])
  route = find_or_create_route!(zone, row["route"]) if row["route"].present?
  client = Client.create!(name:, address:, phone:, zone:, latitude:, longitude:)
  route&.route_stops&.create!(client: client)
end
```

A failure rolls back the zone and route created for that row only, so
"zones and routes are created only when the client is". Zone and route
lookups use `lower(unaccent(name)) = lower(unaccent(?))` (routes scoped to
the zone); new ones are created with the trimmed value as typed. Because
lookups hit the database each row, a zone created by an earlier row is found
by later rows.

The duplicate-name check reuses the model validation, so the row's reason is
the same message the form shows.

### 4. Product rows: find by normalized name, then create or update

`price` is validated against `/\A\d+(\.\d+)?\z/` before touching the
database (so `12.500,00`, `-5` and `abc` fail with "precio inválido").
The product is looked up with the same `lower(unaccent(name))` comparison;
when found, `update!(price:)` and count as updated, otherwise `create!` and
count as created. Price rounding to two decimals is left to the column.

### 5. Coordinates from a Google Maps URL, in `GoogleMaps`

`GoogleMaps.coordinates_from_url(url)` returns `[lat, lng]` or `nil`:
1. Parse the URL; if it is not `http(s)` return `nil`.
2. If the host is a short-link host (`maps.app.goo.gl`, or `goo.gl` with a
   `/maps` path), call `resolve_short_link`, which does a `Net::HTTP` GET
   without following redirects (open/read timeouts of 3 s), reads the
   `Location` header, and repeats only while the next location is still a
   short-link host, up to 3 hops. It never requests any other host; the
   final long URL is only parsed. Any network error returns `nil`.
3. Extract coordinates, first match wins: `!3d<lat>!4d<lng>` (the actual
   place pin), `@<lat>,<lng>`, then a `query`, `q` or `ll` parameter
   matching `<lat>,<lng>`.
4. Return `nil` unless latitude is within ±90 and longitude within ±180.

Tests stub `GoogleMaps.resolve_short_link` (and assert `Net::HTTP` is not
called for other hosts) instead of adding WebMock.

*Alternative:* geocode the address with the Geocoding API. Declined by the
user (cost and server key).

### 6. Controllers, routes and the upload control

- Routes: `resources :clients do collection { post :import } end`, and the
  same for products.
- `ClientsController#import` / `ProductsController#import` call the service
  with `params[:file]`, then `redirect_to` the index with `notice:` (counts)
  and, when there are failures, `alert:` as an array of strings
  ("Fila 3: falta name"), at most 20 plus a "y N filas más" line. An
  `InvalidFile` redirects with that message as the only alert. Twenty short
  lines stay well under the 4 KB cookie session limit.
- `shared/_import_button.html.erb`: a `multipart` `form_with` (POST to the
  import path) containing a `<label>` styled like the secondary buttons that
  wraps a visually hidden `<input type="file" name="file" accept=".csv">`
  with `data-action="change->auto-submit#submit"` on a form with
  `data-controller="auto-submit"`. Clicking the label opens the native file
  picker; choosing a file submits. Reuses the existing `auto-submit`
  controller.
- The index header wraps the create link and the import form in a
  `flex gap-3` group so the import button sits immediately to its right.
- `layouts/_flash.html.erb` renders an array message as a list (`<ul>`),
  and strings as today.

### 7. Seeds with distinct client names

`db/seeds/development.rb` builds names from the shuffled
`CLIENT_NAME_PREFIXES.product(CLIENT_NAME_SUFFIXES)` combinations (40) and
skips any already used, instead of sampling at random, so the new rule
never fails `db:seed`.

## Risks / Trade-offs

- [Google changes its short-link redirect or URL format] → The client is
  still created without a location; the location can be set later with the
  map picker.
- [A large file makes the request slow, especially with short links (up to
  ~9 s per row in the worst case)] → The 2 MB cap and 3 s timeouts bound it;
  if real files turn out large, move the import to a background job later.
- [Outbound requests from user data (SSRF)] → Only the fixed short-link hosts
  are ever requested, with no redirect following beyond them.
- [The new name rule rejects edits to existing duplicate clients] → Only
  development data can have duplicates; the edit form shows the error so the
  name can be fixed.
- [Matching products ignoring accents could update a product the user
  considered different, e.g. "Pina" vs "Piña"] → Accepted for consistency
  with the client rule; the notice reports how many were updated.
- [`12.500` is read as 12.50, not twelve thousand five hundred] → Documented
  format (digits and optional decimal point); the flash shows updated counts
  so the user can check.

## Migration Plan

No database migration. Deploy with `bundle install` (new `csv` gem). In
development, `bin/rails db:seed` regenerates distinct names. Rollback is a
code revert.
