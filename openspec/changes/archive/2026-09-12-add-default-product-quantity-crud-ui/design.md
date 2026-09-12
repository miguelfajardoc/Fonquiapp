## Context

See `proposal.md` - Why/What Changes. `DefaultProductQuantity`
(`app/models/default_product_quantity.rb`) already `belongs_to :product,
:client, :zone` and validates `quantity` (integer `>= 0`) and uniqueness of
`product_id` scoped to `[client_id, zone_id]` — the exact rule described in
`product-ordering`'s "Default product quantity record" requirement, unchanged
here. `Client belongs_to :zone` (its own `zone_id`), so a client's zone is
always known, but `DefaultProductQuantity` stores `zone_id` directly rather
than deriving it through `client.zone_id` (matching `PendingProduct`/
`DailyProductOrder`'s shape); the form must therefore submit `zone_id`
itself, not just infer it from the chosen client. No `DefaultProductQuantitiesController`
or `app/views/default_product_quantities/*` exist yet, and `hotwire_combobox`
is not in the Gemfile.

I researched `hotwire_combobox` (gem `hotwire_combobox`, README + docs at
hotwirecombobox.com) before writing this design:
- Install: add the gem, `bundle install`; no importmap changes are expected
  for apps already using `eagerLoadControllersFrom`/`lazyLoadControllersFrom`
  in `app/javascript/controllers/index.js` (this app already does) — per the
  README, "most apps using importmaps won't need any configuration." Add
  `<%= combobox_style_tag %>` to the layout `<head>` for styles.
- The form builder exposes `form.combobox :attribute, collection_or_url`.
  Passed a URL (a controller action), it becomes an async/remote combobox:
  the browser fetches that URL with a `q` search-text parameter as the user
  types, and the controller responds with `render turbo_stream:
  helpers.async_combobox_options @records` (or a matching `.turbo_stream.erb`
  template).
- I could not find, in the README or hotwirecombobox.com docs, any
  documented mechanism for scoping/updating an async combobox's search
  based on another field's current value (a "dependent select"). This
  design does not rely on one — see the Turbo Frame decision below, which
  only depends on the gem's ordinary async mode and needs no undocumented
  API.
- **Confirmed against the installed gem's source (0.4.1) during
  implementation**, since the docs alone didn't settle every detail: the
  engine (`lib/hotwire_combobox/engine.rb`) registers its own
  `config/hw_importmap.rb` into `app.config.importmap.paths` automatically,
  so no manual pin is needed. `form.combobox :client_id, a_url_string`
  builds an `async_src` via `hw_uri_with_params(url, for_id:, format:
  :turbo_stream)`, which *merges* those two keys onto the given URL's
  existing query string rather than replacing it — so a `zone_id` baked
  into that URL survives. The browser's own per-keystroke search
  (`_filterAsync` in `async_loading.js`/`filtering.js`) only ever adds
  `q`, `input_type`, `for_id`, `callback_id` to that same URL
  (`requestjs`'s `mergeEntries` only touches keys it's given), so `zone_id`
  is never dropped or overwritten by a search request either. The
  controller-side helper is `hw_async_combobox_options` (an alias of
  `hw_paginated_combobox_options`), which defaults `for_id: params[:for_id]`
  — no need to pass it explicitly.

## Goals / Non-Goals

**Goals:**
- Ship a working CRUD flow for `DefaultProductQuantity` (all actions but
  `show`), styled and structured identically to the existing Zonas/
  Clientes/Productos flows.
- Let the Cliente field scale to a large client list via `hotwire_combobox`'s
  async search, scoped to whichever zone is currently selected.
- Changing the selected zone clears the client choice and immediately
  limits the combobox to that zone's clients (per the user's explicit
  direction).
- Connect the sidebar's "Default" submenu entry to the new index, leaving
  "Pendientes"/"Orden Diaria" and the top-level "Productos" entry exactly as
  they are.

**Non-Goals:**
- Any change to `DefaultProductQuantity`'s validations, associations, or the
  `product-ordering` capability's specified rules — this only exposes the
  existing rules through a web flow.
- Building controllers/views for `PendingProduct` or `DailyProductOrder`, or
  linking the submenu's "Pendientes"/"Orden Diaria" entries. They remain
  inert.
- A generic, reusable "searchable client picker" component for the rest of
  the app. The new client-search endpoint is scoped to this flow's needs
  (zone-filtered); a future flow needing a similar picker can factor it out
  then.
- Any keyboard/touch alternative beyond what `hotwire_combobox` already
  provides out of the box (it is a full combobox widget, not a bespoke
  hover-only control like the sidebar's Productos submenu).

## Decisions

### Controller mirrors the existing CRUD controllers

`DefaultProductQuantitiesController` gets `index`, `new`, `create`, `edit`,
`update`, `destroy`, with `set_default_product_quantity`/strong params
(`params.expect(default_product_quantity: [:zone_id, :client_id, :product_id,
:quantity])`). `create`/`update` re-render `new`/`edit` (422) with the
invalid record on validation failure (including the uniqueness violation,
which surfaces through the same generic errors-summary block every other
form already uses — no bespoke copy for this specific error). `destroy`
always succeeds once confirmed, since nothing else references a
`DefaultProductQuantity` (unlike Zone/Client/Product, it is never the
"one" side of a `restrict_with_error` association) — so unlike Zonas/
Productos, there is no blocked-deletion flash path to implement here.

### Zone-scoped client combobox via a Turbo Frame, not undocumented gem internals

The Cliente field is `form.combobox :client_id, client_options_default_product_quantities_path(zone_id:
default_product_quantity.zone_id)`, rendered inside `turbo_frame_tag
"client_combobox"`. `client_options` (a collection route on
`DefaultProductQuantitiesController`) filters `Client.where(zone_id:
params[:zone_id])`, further narrowed by `params[:q]`, and responds with
`render turbo_stream: helpers.hw_async_combobox_options(clients)` — this is
what the combobox's own search-as-you-type fetches as the user types
(confirmed to work exactly as documented once implemented).

Reloading the frame when the zone changes does **not** re-fetch
`client_options` directly. Instead, a small Stimulus controller
(`client_zone_filter_controller.js`) listens for `change` on the Zona
`<select>` and sets the Turbo Frame's `src` to the **current page's own
URL** (`new` or `edit`) with `zone_id` swapped to the newly chosen zone.
Turbo then extracts the matching `<turbo-frame id="client_combobox">` from
that page's fresh render — and since `new`/`edit` build `@default_product_quantity`
from `params[:zone_id]` (via `DefaultProductQuantity.new(zone_id:
params[:zone_id])` on `new`, and `assign_attributes(zone_id: ...,
client_id: nil)` — in memory only, not persisted — on `edit`), the
re-rendered combobox is scoped to the new zone with no client selected,
satisfying "changing zone clears the client choice" without a third,
special-purpose action.

Alternative considered: rely on an undocumented `for_id`-style parameter
inside the gem to filter without a page/frame reload. Rejected — I found
`for_id` used only inside the gem's pagination helper (to disambiguate
which combobox instance a paginated request continues), not as a
documented parent-scoping mechanism; building on it would be guessing at
unstable internals. The Turbo Frame approach only relies on documented,
ordinary Rails/Hotwire behavior (a frame reloading when its `src`
changes) plus the gem's documented async mode.

### `Client#to_combobox_display`

The gem displays each option via `#to_combobox_display` by default (and
raises a clear error naming the missing method otherwise), and also uses it
to pre-fill the combobox's display text for an already-selected value —
`Client` gains `def to_combobox_display; name; end` rather than passing
`display:` at every call site, matching the gem's own suggested extension
point. This pre-fill is automatic: since the field is `client_id`, the
gem infers the `client` association from the form object and reads its
`to_combobox_display` with no extra wiring needed on `edit`.

### Combobox width: overriding `--hw-combobox-width`, not the form's width

The combobox's rendered width does not come from its surrounding markup at
all: `.hw-combobox` (the fieldset the gem renders) is `display: inline-flex`
in the gem's own stylesheet, so it shrink-wraps to its content instead of
stretching to fill its container — unlike a plain `<select>`/`<input>`,
which stretches because it's a direct child of a `flex flex-col` div (flex
items default to stretching along the cross axis). Its actual visible
width comes from `.hw-combobox__main__wrapper`'s `width:
var(--hw-combobox-width)`, a CSS custom property the gem sets to `10rem`
on `:root`. Widening the `<form>` (tried first) had no effect on the
combobox for exactly this reason. The fix is a global override in
`app/assets/tailwind/application.css`:

```css
.hw-combobox {
  --hw-combobox-width: 28rem;
}
```

Declaring it on `.hw-combobox` itself (not `:root`) makes it win regardless
of stylesheet load order, since it sets the property directly on the
element the width rule reads it from, rather than competing with the
gem's own `:root` declaration. The form's `max-w-sm` was bumped to
`max-w-md` (also 28rem) so the plain `<select>`/`<input>` fields — which do
stretch to the form's width — line up with the combobox instead of being
narrower than it.

### Zone and Producto stay plain `<select>`s

Only Cliente uses `hotwire_combobox`, per the user's explicit direction
("a futuro el listado de cliente es muy grande"); Zona and Producto use the
same `form.select` + `options_from_collection_for_select` pattern already
used for `zone_id` in `clients/_form.html.erb`, since neither list is
expected to grow large. Both get an explicit blank/placeholder option
(e.g. "Selecciona una zona"/"Selecciona un producto") so a fresh `new` form
starts with nothing selected — otherwise the browser would default to the
first zone alphabetically, which would silently scope the client combobox
to an unintended zone.

### View structure

- `default_product_quantities/index.html.erb`: "Crear default" button
  above a 4-column table (Cliente / Producto / Cantidad / Acciones); one
  row per record with Editar and Eliminar (opens the shared confirmation
  modal) — same structure as the other indexes. No Zona column, per the
  user's exact column list (the client's own zone is implied).
- `default_product_quantities/_form.html.erb`: Zona select, Cliente
  combobox (in its Turbo Frame), Producto select, Cantidad
  (`number_field`, `min: 0`), submit labeled "Crear"/"Actualizar", and a
  "Cancelar" link — mirrors the other forms' structure and error-summary
  block.
- `new.html.erb`/`edit.html.erb`: thin wrappers rendering the shared form
  with a heading, same as the other flows.
- The existing `shared/_confirm_dialog` partial and `modal_controller.js`
  are reused as-is for delete confirmation.

### Sidebar: only the "Default" submenu entry changes

In `_sidebar.html.erb`, the second submenu `<span>` (`t("nav.products_default")`)
becomes `link_to t("nav.products_default"), default_product_quantities_path`,
styled to match "Productos"'s existing muted-link treatment. "Pendientes"
and "Orden Diaria" stay `<span>`s; the top-level "Productos" entry and the
active-highlighting requirement (which only covers Zonas/Clientes) are
unchanged.

## Risks / Trade-offs

- **A new runtime dependency** (`hotwire_combobox`) is added for a single
  field. Accepted per the user's explicit request and reasoning (future
  client-list scale); no alternative (e.g. a plain `<select>` with
  thousands of `<option>`s) meets that stated goal.
- **The Turbo-Frame reload on zone change causes a full round-trip to the
  server** (rather than an instant client-side filter) every time the zone
  changes. Accepted as the simplest correct approach that doesn't depend on
  guessing the gem's internals; the round-trip is a single small request
  and only fires on zone change, not on every keystroke (the combobox's own
  search-as-you-type still happens client-side against the async endpoint
  per the gem's normal behavior).

## Migration Plan

Mostly additive: new gem, new route/controller/views/partial, one new
Stimulus controller, new locale keys, and small edits to two existing
files (`_sidebar.html.erb`'s "Default" entry, `application.html.erb`'s
`<head>` for `combobox_style_tag`). No changes to `DefaultProductQuantity`
or its migrations. Rollback is removing the gem, the added files/route, and
reverting the two touched files.
