## Context

`DailyProductOrder`, `DefaultProductQuantity`, and `PendingProduct` already
exist as data models (see `product-ordering`), each with `belongs_to
:product, :client, :zone` and their own `zone_id`/`client_id` columns. No
`app/services/` directory exists yet — this is the first feature that needs
plain-Ruby service objects rather than fitting entirely in a controller.
There is also no spreadsheet/export dependency anywhere in the app yet.

Per the clarifying answers on this change: only `pending`-state
`PendingProduct` records count toward generation; generating never changes
`PendingProduct` state; regenerating a zone on the same day replaces that
zone+day's records; the consolidated spreadsheet's product totals come from
the stored `DailyProductOrder` rows of that specific batch (not a live
recompute); and the download is a plain XLSX file, not a real Google Sheets
API document.

## Goals / Non-Goals

**Goals:**
- Keep the aggregation and spreadsheet-building logic in plain Ruby service
  objects (`app/services/`), independent of the controller, so they're
  directly testable without going through a request.
- Reuse the existing zone `<select>` + page-reload pattern already used
  elsewhere (no async combobox needed — the zone list is small).

**Non-Goals:**
- Any UI for manually creating, editing, or deleting an individual
  `DailyProductOrder` — every record is produced (and replaced) only
  through generation.
- Real Google Sheets API integration (per the clarifying answer).
- Recomputing a batch's product totals from live default/pending data at
  download time (per the clarifying answer) — only the per-client
  "currently pending" columns are live, as specced.

## Decisions

### Two plain service objects, not controller-embedded logic

`DailyProductOrderGeneration.new(zone:, day: Date.current).call` and
`DailyProductOrderConsolidation.new(zone:, day:).call` are the only two
services. Splitting them (rather than one "daily order service") mirrors
the two independent actions in the UI (Generar vs. Descargar consolidado),
which can be invoked independently and at different times (a batch can be
downloaded long after it was generated).

### Aggregation queries `DefaultProductQuantity`/`PendingProduct` by their own `zone_id`, not via `Client`

Both tables already carry `zone_id` directly (in addition to `client_id`,
whose own `Client` also has a `zone_id`). Generation filters
`DefaultProductQuantity.where(zone: zone)` and
`PendingProduct.where(zone: zone, state: :pending)` directly, then groups
by `[client_id, product_id]` and sums quantities in Ruby. This avoids a
join through `Client` and matches how every other flow in this app (the
combobox-scoped client pickers, the index listings) already treats a
record's own `zone_id` as authoritative for "which zone is this in."
Skipping a `[client_id, product_id]` pair whose total is 0 satisfies the
"no record for a zero total" requirement without a separate filter pass.

### Regeneration: delete-then-recreate inside one transaction

```ruby
DailyProductOrder.transaction do
  DailyProductOrder.where(zone: zone, day: day).delete_all
  totals.each { |...| DailyProductOrder.create!(...) }
end
```

`delete_all` (not `destroy_all`) is safe here because these records carry
no callbacks or dependent associations of their own to clean up — they are
the "leaf" of the ordering data model. Wrapping both steps in one
transaction means a mid-generation failure leaves the previous batch intact
rather than deleting it and then erroring out with nothing persisted.

### Grouped listing: load all zones once, group `DailyProductOrder` in Ruby

```ruby
@zones = Zone.order(:name)
@batches = DailyProductOrder.select(:day, :zone_id).distinct.order(day: :desc)
```
paired with `@zones.index_by(&:id)` for name lookups in the view. Avoids a
`GROUP BY`/join query that would need care to also carry the zone name;
the zones table is small enough that loading all of them and looking up by
id in-view is simpler than a more elaborate single query, with no
meaningful performance difference at this data size.

### Consolidated XLSX via `caxlsx`

`caxlsx` (the maintained fork of the archived `axlsx`) is the standard
choice for generating `.xlsx` files in a Rails app without extra system
dependencies (pure Ruby, no LibreOffice/soffice shell-out required, unlike
`rubyXL`-adjacent approaches that need a converter for some formats). Its
public API lives under the `Axlsx` module, not `Caxlsx` (confirmed by
reading the installed gem: `lib/caxlsx.rb` just `require_relative 'axlsx'`,
kept for drop-in compatibility with the original `axlsx` gem it forked). A
worksheet is built directly in the service:

```ruby
package = Axlsx::Package.new
package.workbook.add_worksheet(name: "Consolidado") do |sheet|
  sheet.add_row header_row
  zone.clients.order(:name).each { |client| sheet.add_row(*client_row(client)) }
  sheet.add_row []
  sheet.add_row ["Producto", "Cantidad"]
  product_totals.each { |name, qty| sheet.add_row [name, qty] }
end
```

`DailyProductOrdersController#consolidated` streams it back with
`send_data package.to_stream.read, filename: "...", type:
"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"` — no
temp file needed. `:xlsx` is not a MIME type Rails registers by default
(`Mime[:xlsx]` is `nil`, confirmed via `bin/rails runner`), so the type
string is passed literally rather than adding a `Mime::Type.register`
initializer for a single download action.

### The download link needs `data: { turbo: false }`

Found during manual testing: the file downloaded correctly, but the
browser's tab kept showing a loading state indefinitely, with nothing new
in the network tab. Turbo Drive intercepts every link click as a page
"visit" and only clears its progress indicator once that visit's page
finishes loading; a `send_data` response is a file download, not a page
navigation, so no such completion signal ever arrives and Turbo is left
waiting forever. The "Descargar consolidado" link needs `data: { turbo:
false }` so Turbo Drive ignores the click entirely and lets the browser
handle it as a plain, native download.

### Location URL as a clickable link via `escape_formulas: false` on that cell

Confirmed directly against the installed gem (`caxlsx` 4.5.0): there is no
`:formula` cell type — `Cell#type=` only accepts `[:date, :time, :float,
:integer, :richtext, :string, :boolean, :iso_8601, :text]`, and passing
`:formula` raises `Axlsx::RestrictionValidator`'s `ArgumentError`
immediately. Whether a string cell is written out as a live formula
instead of literal text is controlled separately, by `Cell#escape_formulas`
(default `true`, `Axlsx.escape_formulas`, for CSV/formula-injection
safety — a value starting with `=` is otherwise just displayed as text).
`Worksheet#add_row` accepts `escape_formulas:` as one boolean applied to
every cell in the row, or an array of booleans applied by index, exactly
like its existing `types:`/`style:` options. The location cell is
therefore written as a plain string value
`"=HYPERLINK(\"#{client.url}\",\"Ver ubicación\")"`, with that row's
`escape_formulas:` array set to `false` at the location column's index and
`true` (or omitted) elsewhere — verified end-to-end with `bin/rails
runner`: the resulting cell reports `is_formula? == true` and the package
serializes to a valid stream. `add_hyperlink` (a separate relationship
object per cell) was considered and rejected in favor of this, since it
would require tracking cell references outside the plain array-of-values
row-building already used for every other column.

### Dynamic "Pendiente N" columns sized to the widest client, client table lists the whole zone

The client table's row set is every client in the batch's zone
(`Client.where(zone:)`), not just the ones that ended up with a
`DailyProductOrder` in this batch — corrected after manual testing showed
a client with neither a default quantity nor a pending product (so nothing
for `DailyProductOrderGeneration` to persist) silently vanished from the
consolidated sheet, when the actual intent is that every client the zone's
driver might need to visit appears, even if there's nothing due for them
today. The product totals table is unaffected by this and still sums only
`DailyProductOrder` rows that exist in the batch, per the requirement.

Before writing rows, the service computes, for every client in the zone,
that client's **current** `pending`-state `PendingProduct` count, takes
the maximum across all of them, and builds that many `"Pendiente
1"`..`"Pendiente N"` header columns (fixed 3 leading columns: Cliente,
Dirección, Ubicación). Each client's row is padded with blank cells for
any unused pending columns, since a plain array-of-rows XLSX writer needs
every row to align to the same column count for the sheet to read
cleanly.

## Risks / Trade-offs

- [The per-client "pending" columns are read live, while the product
  totals are frozen at generation time — the same download can show data
  from two different points in time] → this is the explicitly chosen,
  clarified behavior (live pending, frozen totals); called out here so a
  future reader doesn't "fix" it as an inconsistency.
- [`delete_all` bypasses model callbacks] → `DailyProductOrder` has none
  today; if validations/callbacks are ever added to it, this decision
  should be revisited.
- [A very large pending count for one client widens the sheet for every
  client's row] → acceptable at this app's scale; not worth a more complex
  per-client variable-width layout.

## Migration Plan

Additive only: new `app/services/`, new controller/views/routes, one new
gem (`caxlsx`), one sidebar link change. No data migration. Rollback is
reverting the commit; no persisted data format changes.
