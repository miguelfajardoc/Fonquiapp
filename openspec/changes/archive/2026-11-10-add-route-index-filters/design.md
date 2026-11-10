## Context

See proposal.md for motivation and the delta specs for the required
behavior. Relevant current state:

- **Filter bars** on the client, default quantity and daily order indexes
  share one pattern: a GET form with the `auto-submit` and
  `client-zone-filter` Stimulus controllers. That form targets the list's
  Turbo Frame (`turbo_action: "advance"` keeps the URL in sync). The route
  select sits in its own Turbo Frame, which `client-zone-filter` reloads
  when the zone changes, and `data-auto-submit-clear-param` blanks the stale
  route. The controls use `filter_control_class`, the `shared.filters.*`
  labels and `shared/clear_filters`. Lists are paginated with
  `pagy(:offset, …)` (limit 20) and `shared/_pagination`.
- **Route filter options** are built in each controller as
  `zone_id ? Route.where(zone_id:).order(:name) : Route.none`:
  `ClientsController#index` (`@routes`),
  `DefaultProductQuantitiesController#load_filters` and
  `DailyProductOrdersController#load_table_filters` (`@filter_routes`). The
  last two also drop a `route_id` that isn't in those options. The daily
  order **generation** select (`DailyProductOrdersController#index`,
  `@routes`) and the default quantity **form** select use the same
  expression but are not filters and stay unchanged.
- `RoutesController#index` loads every route, ordered by zone name and
  route name, with no filters or pagination. `routes/index` has no Turbo
  Frame.
- **Client combobox:** `pending_products/_fields` uses
  `form.combobox :client_id, client_options_pending_products_path`
  (hotwire_combobox 0.4.1, async). That endpoint returns all clients whose
  name contains `q` (ILIKE). The combobox fires `hw-combobox:selection` and
  `hw-combobox:removal` events. With an async source, the combobox shows the
  selected option's name on first render only when it can reach the
  associated record through its `form:` object (`form.object.client`).
  Otherwise it shows the raw id.

## Goals / Non-Goals

**Goals:**
- Reuse the existing filter pieces without adding new Stimulus controllers.
- One place that defines "route filter options" for all four filter bars.

**Non-Goals:**
- Changing form or generation route selects.
- Disambiguating repeated route names across zones (decided: names only).
- Scoping client suggestions to the selected zone (decided: all clients).

## Decisions

### `Route` becomes `Filterable`

Add `include Filterable` and three scopes:
- `filter_by_zone_id` → `where(zone_id:)`
- `filter_by_route_id` → `where(id:)`
- `filter_by_client_id` → `where(id: RouteStop.where(client_id:).select(:route_id))`

The subquery (instead of a join) keeps each route once, so pagination
counts stay right. The full `route_stops: :client` preload still loads
every stop, so each row shows all of its clients.

### Shared route filter options

Add a small controller concern, `RouteFilterOptions`, with one method:

- `route_filter_options(zone_id)` → `Route.joins(:zone).order("zones.name", :name)`,
  plus `.where(zone_id:)` when a zone is given.

Ordering by zone and then name keeps same-named routes in a predictable
place even though only names are shown. The four filter bars use it:
- routes: new
- clients: replaces `@routes`
- default quantities and daily orders: replace `@filter_routes`

The existing "drop a `route_id` not in the options" logic is reused by the
routes, default quantities and daily orders indexes. With no zone the
options are all routes, so a route alone is accepted, and a route outside
the selected zone is still ignored.
*Alternative:* a `Route.filter_options_for(zone_id)` model scope. Rejected
because it's only for filter bars and lives next to the other controller
filter code. Either is fine; the concern also avoids repeating the
`exists?` guard.

The client index keeps its current semantics (zone and route both apply,
as the client-management spec states). Only its options change.

### Route index layout follows the client index

- Filter form: `form_with url: routes_path, method: :get`, with
  `data: { controller: "auto-submit client-zone-filter", turbo_frame: "routes" }`.
- Zone select: `change->client-zone-filter#reload change->auto-submit#submit`
  and `data-auto-submit-clear-param="route_id"`.
- Route select: inside `turbo_frame_tag "route_route_filter"`.
- Client combobox: `client_id`.
- `shared/clear_filters`.

The table, an empty-state row (`routes.index.no_results`) and
`shared/_pagination` go inside `turbo_frame_tag "routes", data: { turbo_action: "advance" }`.
The "Nueva ruta" button and the confirm dialog stay outside the frame,
like on the client index.

### Client filter = the pending product combobox

Use the same async source, `client_options_pending_products_path`, so the
suggestions are exactly those of `pending_products/new` (all clients).
`hw-combobox:selection->auto-submit#submit` and
`hw-combobox:removal->auto-submit#submit` apply the filter. The combobox is
outside the list frame, so it keeps its text while the list refreshes.

On a full page load with `client_id` in the URL, the name must show instead
of the id. To get that, render the combobox through a form builder whose
object responds to `client_id` and `client` (a small `Struct` built in the
controller from the found `Client`). This uses the gem's own
`associated_object` path, with no custom JS.

An unknown or deleted `client_id` gives `client: nil`. The filter then
matches no route and the box stays empty (acceptable for a hand-edited URL).
*Alternative:* a client-name text box like the pending product index.
Rejected because the user asked for the single-client combobox.

### Pagination

`@pagy, @routes = pagy(:offset, scope)` with the same limit (20) as the
other indexes. Pagy keeps the query params in its page links, so the
filters survive paging. A new filter submit drops `page`, so it shows the
first page.

## Risks / Trade-offs

- **[`hw-combobox:selection` may fire before the hidden input has the new
  value, so an older value would be submitted]** → check it in the headless
  browser. If it happens, defer the submit with `auto-submit#debouncedSubmit`
  (already exists) instead of adding code.
- **[Listing every route can make the select long]** → acceptable at
  current volume; choosing a zone narrows it.
- **[Repeated route names are ambiguous with no zone selected]** → accepted
  by the user; the zone-then-name order keeps them grouped.
- **[Reusing a `pending_products` endpoint from the routes page couples the
  two]** → it's the same "pick a client" source by design. If one of them
  needs different suggestions later, give it its own endpoint then.

## Migration Plan

No data or schema changes. Deploy normally; revert the commit to roll back.
