## Context

See proposal.md (Why). Current state that shapes the approach:

- `ClientsController#index` is `Client.includes(:zone).order(:name)`, with no
  params, no pagination, and one full-page render.
- Rows navigate with `row_controller.js` through `Turbo.visit(url)`, which is
  a top-level visit. The delete button opens `shared/_confirm_dialog`, which
  is rendered outside the table. Both keep working if the table moves into a
  Turbo Frame.
- `client_zone_filter_controller.js` already reloads a target Turbo Frame from
  the current URL with `zone_id` swapped in. `daily_product_orders/index`
  uses it for a zone-dependent route select.
- Pagy 43.6 is installed: `Pagy::Method` in `ApplicationController`, limit 20,
  and a per-request `Pagy::I18n.locale`. Its nav is rendered and styled
  inline in `daily_product_orders/index.html.erb`.
- PostgreSQL 18. The `unaccent` and `pg_trgm` extensions are available but
  not installed. `db/schema.rb` only enables `plpgsql`.
- Stimulus controllers are eager-loaded from `controllers/`, so a new
  `*_controller.js` file needs no registration.
- No browser-driven test tooling is available. JS behavior (debounce, focus,
  dependent select) is verified manually.

## Goals / Non-Goals

**Goals:**
- Filter state lives only in the URL query string (`name`, `zone_id`,
  `route_id`, `page`).
- The pieces generalize to other index views with 4 or 5 filters each,
  without any per-view JavaScript.

**Non-Goals:**
- No session persistence of filters.
- No search index (`pg_trgm`/GIN). Client counts are small. Revisit if a
  filtered list gets slow.
- No filters on other views yet. They will reuse these pieces in later
  changes.
- No sorting controls. The order stays by name.

## Decisions

### 1. Plain GET form plus a Turbo Frame instead of AllFutures or Ransack

The filter bar is a `form_with url: clients_path, method: :get`. It targets a
`<turbo-frame id="clients">` that wraps the table, the empty-state row, and
the Pagy nav. The frame has `data-turbo-action="advance"`, so each frame
navigation (filter submit or page link) pushes the full URL into history.

- The form sits **outside** the frame, so typing never re-renders the name
  input and focus stays in place.
- The server renders the full page every time, and Turbo extracts the
  matching frame. A frame-only render optimization is not needed at this
  size.
- *Alternatives*:
  - AllFutures: needs Redis/Kredis, which this Solid-stack app does not run,
    and it keeps state outside the URL.
  - Ransack: adds a gem, needs a `ransackable_attributes` allowlist on every
    model, and is more than 4–5 simple filters need.

### 2. `Filterable` concern with explicit `filter_by_<key>` scopes

```ruby
module Filterable
  extend ActiveSupport::Concern

  class_methods do
    def filter_by(filters)
      filters.to_h.compact_blank.reduce(all) do |scope, (key, value)|
        scope.public_send(:"filter_by_#{key}", value)
      end
    end
  end
end
```

- The controller passes only permitted keys
  (`params.permit(:name, :zone_id, :route_id)`). Arbitrary params can
  therefore never reach `public_send`, and each model declares exactly the
  scopes it supports.
- `Client` scopes:
  - `filter_by_name(v)`:
    `where("unaccent(clients.name) ILIKE unaccent(?)", "%#{sanitize_sql_like(v)}%")`.
    `sanitize_sql_like` escapes `%`, `_`, and `\`, so typed characters match
    literally. `unaccent` is applied to both sides, so "doña" and "dona"
    match each other in either direction.
  - `filter_by_zone_id(v)`: `where(zone_id: v)`.
  - `filter_by_route_id(v)`: `where(id: RouteStop.where(route_id: v).select(:client_id))`.
    A subquery, not `joins`, so no duplicate rows and no `distinct` that
    would clash with `order(:name)` and Pagy's count.
- *Alternative*: a per-view query object (`ClientFilter`). That is more
  ceremony than one-line scopes. Revisit if a view needs cross-field logic.

### 3. Route filter only applies within the selected zone

`index` loads `@routes = Route.where(zone_id: params[:zone_id]).order(:name)`
(none without a zone). Before filtering, the controller drops `route_id`
unless it is one of `@routes`. This covers a hand-edited URL and the brief
moment after a zone change where the old route value is still submitted. In
both cases the result is "zone only" instead of an empty list.

### 4. Dependent route select reuses the existing frame pattern

The route `<select name="route_id">` sits in
`<turbo-frame id="client_route_filter">`, inside the filter form. The zone
select fires two actions in order:
1. `client-zone-filter#reload`: re-fetches the current URL with the new
   `zone_id`. The new frame contains only that zone's routes, with none
   selected.
2. `auto-submit#submit`: first blanks the fields named in its `clear` param
   (`route_id`), then submits, so the URL does not carry a stale route.

### 5. Generic `auto-submit` Stimulus controller

`app/javascript/controllers/auto_submit_controller.js` has two actions:
- `submit`: blanks any field listed in the `clear` action param, then calls
  `this.element.requestSubmit()`.
- `debouncedSubmit`: the same after 300 ms of inactivity. Used on the name
  `input` event.

It knows nothing about clients, so any filter form can reuse it with
`data-controller="auto-submit"` plus `data-action` attributes. A filter
submit has no `page` field, so it always lands on page 1. Pagy page links
are built from the frame request's URL, so they keep the active filters.

### 6. `unaccent` through a migration

`enable_extension "unaccent"` in its own migration. `db/schema.rb` then
records it, so `db:prepare` enables it on the test database. `unaccent` is a
trusted extension (PostgreSQL 13+), so a database owner can create it
without superuser rights.

### 7. Shared Pagy nav partial

Move the styled Pagy nav from `daily_product_orders/index.html.erb` into
`app/views/shared/_pagination.html.erb` (renders nothing when
`pagy.pages <= 1`). Use it on both pages, so later filtered views reuse one
nav style.

## Risks / Trade-offs

- [The production DB user may lack permission to `CREATE EXTENSION`, and
  the deploy migration would fail.] → Before deploying, check that the app
  user owns the database. If it does not, run `CREATE EXTENSION unaccent;`
  once as a superuser. The migration is then a no-op.
- [`unaccent(name) ILIKE` cannot use a plain index, so every filter is a
  sequential scan.] → This is fine for hundreds of clients. If needed, the
  later fix is `pg_trgm` plus a GIN index on an immutable `unaccent` wrapper.
- [The debounce, focus retention, and dependent-select clearing cannot be
  covered by request specs.] → Request specs cover all server behavior. The
  JS behavior has a manual verification task.
- [A filter submit and the route frame reload are two requests on a zone
  change.] → Both are cheap. The server-side route guard (decision 3) makes
  the result correct regardless of which finishes first.

## Migration Plan

1. Run the `enable_extension "unaccent"` migration. It is reversible:
   `disable_extension`.
2. Deploy code and migration together. No data changes.
3. Rollback: revert the code and run the migration's `down`.
