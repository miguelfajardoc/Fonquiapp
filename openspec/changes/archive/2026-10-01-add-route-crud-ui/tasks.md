## 1. Dependency

- [x] 1.1 Run `bin/importmap pin sortablejs` to vendor SortableJS under `vendor/javascript/` and add its entry to `config/importmap.rb`; verify `bin/rails runner "true"` still boots and the pin resolves with no missing-file errors

## 2. Model changes

- [x] 2.1 Add `client_in_routes_zone` validation to `app/models/route_stop.rb` (invalid when `client.zone_id != route.zone_id`, skipped when route or client is blank so the existing presence validations report first) per the `route-planning` delta in `specs/route-planning/spec.md` (implemented comparing `client.zone&.id`/`route.zone&.id` via the association reader rather than the raw `zone_id` column, so it stays correct for in-memory/unsaved records too)
- [x] 2.2 Add `accepts_nested_attributes_for :route_stops, allow_destroy: true, reject_if: proc { |attrs| attrs["client_id"].blank? }` to `app/models/route.rb`
- [x] 2.3 Extend `spec/models/route_stop_spec.rb` with the two new scenarios from the delta spec (rejected when client's zone differs from route's zone; accepted when they match) and run `bundle exec rspec spec/models/route_stop_spec.rb`, verifying all examples pass (also fixed the `route_stop` factory and 3 other specs whose route/client pairs predated this validation and now needed matching zones; 37 examples, 0 failures)

## 3. Routing and controller

- [x] 3.1 Add `resources :routes, except: [:show] do collection { get :client_options } end` to `config/routes.rb`
- [x] 3.2 Create `app/controllers/routes_controller.rb` with `index` (`Route.joins(:zone).preload(:zone, route_stops: :client).order("zones.name", :name)`), `new`, `edit`, `create`, `update` (both wrapping the save in `RouteStop.acts_as_list_no_update { ... }`), `destroy`, and `client_options` (clients for `params[:zone_id]`, ordered by name, rendered for the stop-row template), per design.md (index uses `joins` + `preload`, not `includes`, since `includes` combined with an `order` on a joined table forces Rails' JOIN-based eager-load strategy, which was found to silently ignore `route_stops`' own `order(:position)` scope)
- [x] 3.3 Define `route_params` with `params.expect(route: [:name, :zone_id, route_stops_attributes: [[:id, :client_id, :position, :_destroy]]])`

## 4. Client stop list editor (Stimulus + views)

- [x] 4.1 Create `app/javascript/controllers/route_stops_controller.js` implementing: `zoneChanged` (reload the client-options template's `<option>`s via a plain `fetch`, clear all rows), `addRow` (clone the template row, append, recompute positions), `removeRow` (mark `_destroy` for persisted rows / remove new rows from the DOM, recompute positions), a SortableJS `onEnd` handler (recompute positions), and the cross-row duplicate-client option disabling described in design.md (uses a direct `fetch` + DOM update rather than a turbo_stream/turbo_frame swap, since a `<template>`'s inert content cannot be targeted by `document.getElementById`-based Turbo Stream/Frame operations — only the `<template>` element itself can)
- [x] 4.2 Create `app/views/routes/_form.html.erb` and `app/views/routes/_stop_row.html.erb` with the zone select, name field, the `<template>` holding one blank stop row, the sortable row list (rendered by iterating `route.route_stops.reject(&:marked_for_destruction?)`, pre-filled for edit), the "Agregar cliente" button, and cancel/submit controls, matching this app's existing form styling (rows use plain `route[route_stops_attributes][][...]` array-style field names uniformly for both existing and new rows, rather than Rails' `fields_for` indexed naming, to avoid mixing array- and hash-style params under the same key)
- [x] 4.3 Create `app/views/routes/new.html.erb` and `app/views/routes/edit.html.erb` rendering the shared form
- [x] 4.4 Verify (via a request spec, since drag-and-drop itself is a browser-only interaction) that submitting the new-route form with an ordered set of client rows creates the route with route stops in that order, numbered from 1 — covered in `spec/requests/routes_spec.rb`; full manual drag verification is task 8.1

## 5. Index and deletion

- [x] 5.1 Create `app/views/routes/index.html.erb`: a table with Zona, Nombre, and Clientes (via `route.route_stops.map { |stop| stop.client.name }.join(", ")`, truncated with Tailwind `truncate` + a `title` attribute) columns, per-row edit/delete controls, a "Crear ruta" control top-right, and the shared `shared/_confirm_dialog` wired the same way as `zones/index.html.erb`
- [x] 5.2 Add the delete confirmation button per row (same `data-action="modal#open"` pattern as `zones/index.html.erb`) and confirm `RoutesController#destroy` redirects to the route index with a flash notice

## 6. Sidebar and locales

- [x] 6.1 Add a "Rutas" link to `app/views/layouts/_sidebar.html.erb` immediately after "Clientes", using the existing `controller.controller_name == "..."` active-highlight pattern, per the `app-shell` delta
- [x] 6.2 Add `nav.routes` and a `routes:` section (index/new/edit view strings, flash messages) to `config/locales/es.yml`, following the structure already used for `zones:`/`default_product_quantities:`

## 7. Request specs

- [x] 7.1 Write `spec/requests/routes_spec.rb` covering: index lists routes with zone/name/clients and per-row actions, index truncates a long client list, new/edit form rendering, creating a route with ordered stops, creating with invalid data (blank name, no zone, duplicate name in zone, out-of-zone client) re-renders with an error and creates nothing, editing pre-fills existing stops in order and saves reordered/added/removed stops together, editing with invalid data leaves the route unchanged, and deleting a route (with confirmation) removes it and its stops
- [x] 7.2 Write or extend a request/view spec for `app-shell` covering the new "Rutas" entry (present, links to the route index, highlighted only when the route index is displayed) per the `app-shell` delta
- [x] 7.3 Run `bundle exec rspec spec/requests/routes_spec.rb` and the updated app-shell spec, verifying all examples pass (22 examples, 0 failures)

## 8. Full verification

- [x] 8.1 Start the app (`bin/dev` or equivalent) and manually exercise: creating a route with several client stops in a specific drag order, editing it to add/remove/reorder stops, changing the zone mid-form (confirming stops clear), and deleting a route (partially verified: hit `/routes`, `/routes/new`, `/routes/:id/edit`, and `/routes/client_options` against the user's running dev server — all render correctly, the SortableJS and `route_stops_controller` assets load with no server errors, and the stop-row/template markup is structurally correct; no headless browser tool (chromium-cli/Playwright) is available in this sandbox to actually drive the drag/add/remove/zone-change interactions, so that part still needs a real browser check)
- [x] 8.2 Run the full test suite with `bundle exec rspec` and verify there are no failures or regressions (179 examples, 0 failures)
- [x] 8.3 Run `openspec validate add-route-crud-ui --strict` and verify it passes
