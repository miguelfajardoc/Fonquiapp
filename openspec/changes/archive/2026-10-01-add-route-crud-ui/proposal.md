## Why

`Route` and `RouteStop` exist as data models (see `route-planning`) but have
no web interface yet — staff can only create and order routes through the
console. Dispatch needs a page to create/edit routes and, most importantly,
an easy way to pick which clients belong to a route and set/change their
visiting order without leaving the form.

## What Changes

- Add a route index page: one table listing every route's zone, name, and
  clients (truncated with an ellipsis when the list is long), with per-row
  edit/delete controls and a "create route" control in the top-right corner
  — the same index-only shape already used by `zone-management` and
  `product-management` (no per-route detail/"show" page).
- Add a single create/edit form for a route: a zone select, a name field,
  and a repeatable, drag-and-drop-orderable list of client rows (one
  `<select>` per row, scoped to the chosen zone) backed by
  `accepts_nested_attributes_for :route_stops`. Reordering, adding, and
  removing rows all happen client-side; the whole route and its route stops
  save together in one submit. Editing pre-fills the list with the route's
  existing stops in their current order.
- Add drag-and-drop reordering of the client rows using SortableJS (a new
  JS dependency, pinned via importmap — no bundler needed), wired through a
  small Stimulus controller that recomputes each row's position from its
  DOM order after any add/remove/drag.
- Restrict the client rows to clients belonging to the route's currently
  selected zone, both in the UI (the row `<select>`'s options) and as a
  `RouteStop` model validation, so a route stop can never reference a
  client from a different zone regardless of how it's created.
- Add delete-with-confirmation for a route, following the existing shared
  confirmation dialog pattern; deleting a route removes its route stops
  too (`dependent: :destroy`, already in place).
- Add a "Rutas" entry to the sidebar, linking to the route index, positioned
  directly below "Clientes" as a new top-level (non-submenu) entry.

## Capabilities

### New Capabilities
- `route-management`: the web interface staff use to list, create, edit,
  and delete routes, including managing and reordering a route's client
  stops in one form.

### Modified Capabilities
- `route-planning`: the "Route stop record" requirement gains a new
  constraint — a route stop's client must belong to the same zone as its
  route — enforced by the model regardless of how the record is created.
- `app-shell`: the "Top-level navigation entries" and "Active section
  highlighting" requirements gain a "Rutas" entry, positioned after
  "Clientes" and before "Productos".

## Impact

- **Code**: new `RoutesController`, `app/views/routes/*` (index, new, edit,
  shared `_form`), a Stimulus controller for the drag-and-drop stop list
  (plus reuse of the existing zone-reload-frame pattern from
  `default_product_quantities` for scoping the client rows to a zone).
  `Route` gains `accepts_nested_attributes_for :route_stops, allow_destroy:
  true`. `RouteStop` gains a zone-consistency validation.
- **Dependencies**: adds SortableJS, pinned via `config/importmap.rb` from a
  CDN (no bundler/build step required, consistent with this app's existing
  importmap-only JS setup).
- **Routes**: `resources :routes, except: [:show]`.
- **UI**: `app/views/layouts/_sidebar.html.erb` gains a "Rutas" link.
- **Tests**: new request specs for `RoutesController`, updated
  `spec/models/route_stop_spec.rb` for the zone-consistency validation, and
  an updated app-shell request/view spec for the new sidebar entry.
