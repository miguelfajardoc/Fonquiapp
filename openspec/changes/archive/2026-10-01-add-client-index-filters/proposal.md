## Why

The client index lists every client in one unfiltered table, ordered by name.
As clients are spread across zones and routes, staff need to find a client
quickly by name, or see only the clients of one zone or one route, without
scrolling the whole list. This is also the first of several index views that
will get filters (up to 4 or 5 each). The pieces built here should be reusable
for those views.

## What Changes

- Add a filter bar above the client table with three filters, all optional
  and combinable:
  - **Name**: a text box that matches clients whose name *contains* the typed
    text, ignoring upper/lower case and accents (for example, "jose" matches
    "San José" and "doña" matches "Dona Rosa").
  - **Zone**: a select listing every zone.
  - **Route**: a select listing only the routes of the selected zone. It
    offers no routes until a zone is chosen and is cleared when the zone
    changes. It matches clients that are stops of that route.
- Filters apply automatically: as the user types (with a short debounce) or
  when a select changes. There is no "search" button. Only the table area
  refreshes, so focus stays in the name box while typing.
- The active filters live in the URL query string, so reloading, the browser
  back button, and sharing a link keep them. They are **not** remembered in
  the session: leaving the index and returning through the sidebar shows it
  unfiltered.
- Add a "Ruta" column after "Zona" in the client table, listing every route
  the client is a stop of (sorted, comma-separated, or empty).
- Paginate the client table with Pagy (20 per page, already installed). The
  page links keep the active filters, and changing a filter returns to the
  first page.
- Enable the PostgreSQL `unaccent` extension through a migration.
- Introduce reusable building blocks for later filtered views: a `Filterable`
  model concern (maps filter params to `filter_by_<name>` scopes), a generic
  `auto-submit` Stimulus controller, and the existing zone-dependent Turbo
  Frame pattern for dependent selects.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `client-management`: the client index listing gains name/zone/route
  filters and pagination.

## Impact

- **Database**: new migration `enable_extension "unaccent"`.
- **Models**: new `app/models/concerns/filterable.rb`. `Client` gets
  `filter_by_name`, `filter_by_zone_id`, and `filter_by_route_id` scopes.
- **Controller/views**: `ClientsController#index` (filtering, Pagy, routes for
  the selected zone), `clients/index.html.erb` (filter form, route select
  frame, table in its own Turbo Frame, Pagy nav), `es.yml` strings.
- **JavaScript**: new `auto_submit_controller.js`. The zone/route frame reuses
  `client_zone_filter_controller.js`.
- **Dependencies**: none new. Pagy is already installed and `unaccent` ships
  with PostgreSQL.
- **Deploy**: the migration needs permission to create the extension in
  production (see design.md).
- **Tests**: `spec/models/client_spec.rb`, `spec/requests/clients_spec.rb`.
