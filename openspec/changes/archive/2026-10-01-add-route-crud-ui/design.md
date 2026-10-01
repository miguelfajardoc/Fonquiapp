## Context

See proposal.md - Why. Relevant existing patterns this design reuses rather
than reinventing (see `default_product_quantities`, `zones`, and their
views/controllers/JS):

- A zone `<select>` that reloads a Turbo Frame scoped to `zone_id` on
  `change`, via a small single-purpose Stimulus controller
  (`client_zone_filter_controller.js`) that swaps the frame's `src` to the
  current page's own URL with `zone_id` set - the frame's fresh render
  naturally clears whatever it previously held.
- A single shared `<dialog>` (`shared/_confirm_dialog`) driven by
  `modal_controller.js`, reused by every row of an index table for
  delete-with-confirmation.
- Plain `<select>` fields styled with the same Tailwind classes everywhere;
  no async/tag combobox is used except where search matters
  (`hotwire_combobox`, used for the single client field in
  `default_product_quantities`, not needed here since the user asked for a
  plain per-row select).
- JS ships only via `importmap-rails` (`bin/importmap pin <package>`
  vendors a file under `vendor/javascript/`, no bundler). `acts_as_list` is
  already a dependency (added in `add-route-route-stop-models`); `Route`
  already has `has_many :route_stops, -> { order(:position) },
  dependent: :destroy` and `has_many :clients, through: :route_stops`, so
  `route.clients` already returns clients in stop order for free.

A key implementation fact discovered while designing this: `acts_as_list`
assigns/reshuffles `position` per single create/update/destroy (its
`avoid_collision` and `update_positions` callbacks), which fights a
"rebuild the whole ordered list client-side, save once" flow. The gem ships
exactly the escape hatch this needs: `RouteStop.acts_as_list_no_update { }`
disables all of its position-maintaining callbacks for the duration of a
block, letting the controller write whatever `position` values the
submitted row order implies.

## Goals / Non-Goals

**Goals:**
- Ship route index/create/edit/delete matching this app's existing
  index-only management-page shape (`zone-management`,
  `product-management`): one table, edit/delete per row, create button
  top-right, no per-route detail page.
- Let a user build and reorder a route's client stops entirely client-side
  (add row, remove row, drag to reorder) and persist the route and all its
  stops in a single form submission.
- Enforce, at the model layer, that a route stop's client belongs to its
  route's zone - not just as a UI filter.

**Non-Goals:**
- No per-route detail/"show" page (confirmed with the user).
- No server round-trip per add/remove/drag - only the zone-scoped client
  list is fetched from the server (once per zone change); everything else
  is DOM manipulation until the single submit.
- No offline/no-JS fallback for the stop editor - consistent with the rest
  of this app, which already requires JS for modals and comboboxes.
- No keyboard-only drag-reorder affordance beyond whatever SortableJS
  provides out of the box - not required by the proposal, can be revisited
  later if accessibility needs surface.

## Decisions

### Routing and controller

`resources :routes, except: [:show]`, mirroring `zones`/`products`.
`RoutesController` follows the same shape as `DefaultProductQuantitiesController`:

```ruby
def index
  @routes = Route.includes(:zone, :clients).order("zones.name", :name)
end

def create
  @route = Route.new(route_params)
  if RouteStop.acts_as_list_no_update { @route.save }
    redirect_to routes_path, notice: t("routes.flash.created")
  else
    render :new, status: :unprocessable_content
  end
end

def update
  if RouteStop.acts_as_list_no_update { @route.update(route_params) }
    redirect_to routes_path, notice: t("routes.flash.updated")
  else
    render :edit, status: :unprocessable_content
  end
end

def client_options
  clients = Client.where(zone_id: params[:zone_id]).order(:name)
  # renders the stop-row <template> (see below) scoped to these clients
end

private

def route_params
  params.expect(route: [:name, :zone_id, route_stops_attributes: [[:id, :client_id, :position, :_destroy]]])
end
```

`create`/`update` both wrap the save in `RouteStop.acts_as_list_no_update`
so the positions submitted by the form (computed client-side from DOM
order) are written as-is, with no `acts_as_list` shuffling.

### Model changes

`Route`:
```ruby
accepts_nested_attributes_for :route_stops, allow_destroy: true,
  reject_if: proc { |attrs| attrs["client_id"].blank? }
```
`reject_if` guards against a row that was added but never given a client
(e.g. a stray submit) - it is silently dropped rather than raising a
validation error, since "a route MAY have zero stops" is already the
model's behavior.

`RouteStop` gains the zone-consistency validation from the `route-planning`
delta:
```ruby
validate :client_in_routes_zone

private

def client_in_routes_zone
  return if route.nil? || client.nil?
  errors.add(:client, :invalid) unless client.zone_id == route.zone_id
end
```

### The client stop list editor

One Stimulus controller, `route_stops_controller.js`, scoped to the
create/edit form, owns the whole editor:

- **Zone change** (`data-action="change->route-stops#zoneChanged"` on the
  zone `<select>`): reloads a Turbo Frame wrapping a `<template>` tag whose
  content is the selected zone's clients as `<option>`s (rendered by the
  new `client_options` action, reusing the same `zone_id`-keyed
  frame-reload trick as `client_zone_filter_controller`, just targeting a
  `<template>` instead of a live combobox) - and clears every row already
  in the list, per the confirmed "changing zone resets stops" behavior.
- **Add row** (`+ Agregar cliente` button): clones the template's
  `<option>` set into a new row (a `<select>` + hidden `position` input +
  hidden `_destroy` input + remove button), appends it to the list, then
  recomputes positions.
- **Remove row**: for a persisted stop (has a hidden `id`), sets its
  `_destroy` hidden input to `1` and hides the row (so
  `accepts_nested_attributes_for` deletes it on save); for a new row (no
  `id`), removes the DOM node outright. Then recomputes positions.
- **Drag reorder**: SortableJS is initialized on the row list at `connect()`
  with an `onEnd` callback that recomputes positions. SortableJS is pinned
  via `bin/importmap pin sortablejs` (vendored under `vendor/javascript/`,
  no CDN reference at runtime, consistent with `turbo-rails`/`stimulus`).
- **Recompute positions**: one function, called after add/remove/drag,
  walks the non-removed rows in DOM order and writes `index + 1` into each
  row's hidden `position` input. This is the single source of truth for
  what gets submitted - no other bookkeeping needed.
- **Cross-row duplicate prevention (UX polish)**: on every row select's
  `change` and after add/remove, the controller disables each already-
  chosen client's `<option>` in every other row's `<select>`. This is a
  client-side convenience only; `RouteStop`'s uniqueness validation (already
  in place) remains the actual enforcement, so a bypassed/stale form still
  fails safely with a visible error.

On re-render after a validation error, `fields_for :route_stops` on the
in-memory (unsaved) `@route` naturally redisplays exactly the rows the user
submitted, in submitted order - standard Rails nested-attributes behavior,
no special-casing needed.

### Index display

`route.clients` (already ordered via the model's `has_many :route_stops, ->
{ order(:position) }`) is joined into a single string and shown in a table
cell with Tailwind `truncate` + a `title` attribute holding the untruncated
list, matching this app's plain-table-cell style elsewhere.

### Sidebar

Add the "Rutas" link to `app/views/layouts/_sidebar.html.erb` right after
"Clientes", using the same `controller.controller_name == "..."` inline
active-class pattern already used for "Zonas"/"Clientes" (a plain top-level
link, not a hover submenu like "Productos").

## Risks / Trade-offs

- [Destroying a route destroys its route stops one at a time via `dependent:
  :destroy`, so each triggers `acts_as_list`'s `after_destroy` position
  shuffle before the next one is destroyed too] → Harmless at this app's
  scale (a handful of stops per route); not worth wrapping in
  `acts_as_list_no_update` for a one-time delete.
- [Reordering/adding/removing rows relies on JavaScript; there's no no-JS
  fallback] → Consistent with the rest of this app (modals, comboboxes
  already require JS); not a new limitation.
- [Cross-row duplicate-client prevention is client-side only] → The
  existing `RouteStop` uniqueness validation is the real backstop; a
  bypassed form still fails safely with a visible error instead of
  corrupting data.
