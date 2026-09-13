## Context

`PendingProduct` (`belongs_to :product`, `:client`, `:zone`; `enum :state,
{ pending: 0, delivered: 1, canceled: 9 }`) already exists as a model with
its own validations (see `product-ordering` spec / `app/models/pending_product.rb`).
This change only adds the routes/controller/views on top of it.

The app already has a working reference implementation for the trickiest
piece — an async, searchable client picker — built for
`default-product-quantity-management`: `hotwire_combobox` (`form.combobox`),
a Turbo Frame around it, and a small Stimulus controller that reloads the
frame's `src` (pointing back at the current page) when a related field
changes. That existing `client_zone_filter_controller.js` reacts to a plain
`<select>`'s native `change` event and always redirects to zone-scoped
`client_options`. This change needs something related but different: react
to the *combobox's own* selection (not a `<select>`), with no zone scoping
at all (the client list here is never filtered by zone), and use the
selection to drive a live, replaced content area rather than just refining
choices inside the same field.

Confirmed by reading the installed gem (`hotwire_combobox` 0.4.1,
`app/assets/javascripts/hotwire_combobox.esm.js`): selecting a value fires
a `bubbles: true` custom event `hw-combobox:selection` on the combobox's
own element, with `event.detail.value` already holding the selected
record's id as a string (no need to read a hidden input). Clearing the
field fires `hw-combobox:removal` the same way, with `value` empty. Both
events bubble, so a Stimulus controller on a wrapping element can catch
them via `data-action="hw-combobox:selection->…"` without touching the
gem's own markup.

## Goals / Non-Goals

**Goals:**
- Reuse the existing shared components (`shared/_confirm_dialog`,
  `modal_controller`, i18n/currency/date conventions, Tailwind design
  tokens) rather than inventing parallel ones.
- Make the "live update, no full page reload" requirements work
  identically whether triggered from the index page or the create page's
  client-scoped list, without the controller needing to know which page
  triggered the request.

**Non-Goals:**
- Changing the `PendingProduct` model, its validations, or its `state`
  enum values.
- Building any UI path that can set `state` to `canceled` (per the
  clarified scope: the toggle only switches Pendiente ⇄ Entregado;
  `canceled` styling is included for when a future change adds a way to
  reach it).
- Zone selection anywhere in this UI — the zone is always taken from the
  chosen client.

## Decisions

### Routes

```ruby
resources :pending_products, except: [:show] do
  member do
    patch :toggle_state
  end
  collection do
    get :client_options
  end
end
```

`toggle_state` is a member route rather than reusing `update` because it
changes exactly one thing (state, between two fixed values) triggered by a
single-purpose button, independent of the edit form/modal. `client_options`
mirrors the existing `default_product_quantities#client_options` action but
is **not** zone-scoped: `Client.order(:name)`, optionally filtered by `q`
via `ILIKE`, rendered with the same `hw_async_combobox_options` helper
already used by the default-product-quantity flow.

### Client selection: unscoped combobox, no cascading select

Unlike the default-product-quantity form, there is no zone `<select>` to
cascade from — the create form's only fields are client, product, and
quantity. `form.combobox :client_id, client_options_pending_products_path`
searches the full client list directly.

### Zone is derived from the chosen client, not asked for

`PendingProduct.zone_id` is required by the model but is never shown as a
form field, per the explicit field list in the proposal. The controller
sets it from the chosen client: `client.zone_id`. This mirrors how the
`state` field also isn't shown on the create form — it's implicitly
`pending`.

### One turbo-frame per page, `src`-navigated on client change

The create page wraps its client-scoped list in a single
`turbo_frame_tag "pending_product_client_panel"`. A new
`pending_product_client_filter_controller.js` Stimulus controller listens
for `hw-combobox:selection` and `hw-combobox:removal` (bubbled up from a
wrapping element around the combobox) and sets the frame's `src` to the
create page's own URL (`new_pending_product_path`) with `client_id` set to
`event.detail.value` (or removed, when cleared). This is the same
"reload this page's own frame with a query param" pattern already proven
for zone-scoped clients, adapted to a combobox-fired event instead of a
`<select>`'s `change` event and with one field (`client_id`) instead of
two.

`PendingProductsController#new` reads `params[:client_id]`: when present,
it loads `@selected_client` and `@client_pending_products` (that client's
pending products, newest first); when absent, the frame renders an empty
state ("Selecciona un cliente para ver sus pendientes").

### Row markup differs by context; a `context` param picks the right partial

The proposal requires the index to be a real `<table>` ("similar a las
otras") but explicitly asks the create page's client-scoped list to *not*
be a table. That means a pending product's row can't be one literal
shared `<tr>` partial — the index needs `<tr>`/`<td>`s, the panel needs a
div/grid row. Rather than duplicate the row's content, only the
Editar/Eliminar/toggle controls and the state badge are shared
(`pending_products/_actions`, `pending_products/_state_badge`); the row
shell itself is two thin partials (`_row` for the index, `_panel_item` for
the panel) that both render those shared pieces.

Because the two shells differ, an update/toggle response must know which
one to re-render. Each row's Editar and toggle controls carry a `context`
query param (`"table"` from `_row`, `"panel"` from `_panel_item`) on their
URLs (`edit_pending_product_path(record, context:)`,
`toggle_state_pending_product_path(record, context:)`); the edit form
carries it forward via its own `url:` override so `update` sees it too.
`update`/`toggle_state` use `params[:context]` only to pick which partial
to render for the `dom_id(pending_product)` replace — never to change
behavior. Every row still has exactly one `dom_id(pending_product)` no
matter which shell renders it, so the id itself still doesn't need any
context to target correctly; `destroy`'s `turbo_stream.remove` needs no
partial at all, so it needs no context either.

- The list of a specific client's pending products (inside the create
  page's turbo-frame) is wrapped in a second, inner element with id
  `dom_id(client, :pending_products)`. This id is distinct from the outer
  frame's static id so that a full frame navigation (client change) and an
  in-place stream replace (record created) can target different things:
  the frame's `src` swap replaces the whole panel (including the "Pendientes
  Cliente X" heading), while `create`'s turbo_stream response only needs to
  replace the inner list.

Given this, every mutating action's turbo_stream response is:
- `create` (success): `turbo_stream.replace` the whole inner list
  (`dom_id(@selected_client, :pending_products)`) with a freshly queried
  list including the new record, plus replace the form partial with a
  blank one (so quantity/product reset for the next entry). Replacing
  the whole list (rather than appending just the new row) avoids having
  to separately patch away an "this client has no pending products yet"
  empty-state message that may currently occupy that container.
- `create` (failure): `turbo_stream.replace` the form partial in place,
  showing errors, status `:unprocessable_content`.
- `update` / `toggle_state` (success): `turbo_stream.replace` targeting
  `dom_id(pending_product)`, rendering `_row` or `_panel_item` per
  `params[:context]` — lands on whichever page currently renders that row.
- `update` (failure): re-render `edit.html.erb` (wrapped in the modal's
  turbo-frame, see below) with status `:unprocessable_content` — Turbo
  finds the matching frame by id wherever it is in the document, including
  inside an open `<dialog>`.
- `destroy`: `turbo_stream.remove` targeting `dom_id(pending_product)`,
  with an `html` fallback (redirect to index with a flash notice) for
  non-Turbo-Stream requests, matching the rest of the app's destroy
  actions.

No action needs to guess which *page* issued the request — only, for
`update`/`toggle_state`, which row *shell* to render, and that travels
explicitly as `context` rather than being inferred.

### Shared edit modal via a per-page `<dialog>` + turbo-frame

Both the index and the create page each render their own
`shared/_pending_product_edit_modal` partial: a `<dialog>` (styled like
`shared/_confirm_dialog`) containing an empty
`turbo_frame_tag "pending_product_edit_modal"`, driven by a new
`pending_product_edit_modal_controller.js`:
- `open({ params: { url } })`: sets the frame's `src` to the record's edit
  URL and calls `dialog.showModal()`. Each row's "Editar" button carries
  `data-action="pending-product-edit-modal#open"` and
  `data-pending-product-edit-modal-url-param="<%= edit_pending_product_path(record, context:) %>"`
  (`context` is `"table"` from `_row` and `"panel"` from `_panel_item`, per
  the row-markup decision above).
- `close()`: `dialog.close()` — wired to the modal's Cancel button, like
  the existing confirm dialog.
- `submitEnd(event)`: listens for the bubbled `turbo:submit-end` event
  from the form inside the frame; if `event.detail.success`, closes the
  dialog. On failure, the frame already re-rendered in place with the
  validation error (per the `update` failure branch above) and the dialog
  stays open.

`PendingProductsController#edit` renders `edit.html.erb` wrapped in
`turbo_frame_tag "pending_product_edit_modal"` with `layout: false` (a
frame-only response — no sidebar/header needed since it's only ever loaded
into the modal's frame, never visited directly as a full page).

This is the same two-controller split already used for delete
confirmation (`modal_controller` + `shared/_confirm_dialog`), applied to a
form instead of a static confirmation — kept as a separate controller
rather than extending `modal_controller`, since its job (drive a frame's
`src`, react to `turbo:submit-end`) is meaningfully different from the
existing one (fill in a name and a form action).

### State toggle button

A `button_to t(...), toggle_state_pending_product_path(record, context:), method: :patch`
next to each row's Editar/Eliminar controls. Turbo intercepts this form
submission like any other and requests `turbo_stream` automatically; the
controller flips `pending` ⇄ `delivered` (raising if called on a
`canceled` record is unnecessary — the button simply isn't rendered for
`canceled` rows) and responds with the same row-replace stream as `update`.

### State badge colors

Both badges use a low-opacity tint of their color as background with the
solid color as text (`bg-accent/10 text-accent`), so no separate
"contrast" color is needed. "Pendiente" reuses the existing `--accent`
token (already the app's one highlight color, used for primary buttons).
"Entregado" gets one new token, `--state-delivered`, defined in
`app/assets/tailwind/application.css` alongside the existing tokens (light
value + a dark-mode override, same as every other color in that file).
"Cancelado" renders with the same neutral text color as ordinary table
text — no new token needed.

### Date formatting

No existing view formats a date/time yet, and the app has no `rails-i18n`
gem — `config/locales/es.yml` only defines the specific keys the app
actually uses (e.g. currency), relying on `:en` fallback for everything
else. Rails' built-in `l(date, format: :short)` would therefore fall back
to English month abbreviations ("Sep 12") with no `es` override in place,
which would leak English into an otherwise all-Spanish UI. `created_at` is
shown with `pending_product.created_at.strftime("%d/%m/%Y")` instead —
locale-independent and consistent with how the app already avoided
depending on `rails-i18n` for currency formatting.

## Risks / Trade-offs

- [Turbo Stream targeting by DOM id relies on a record's row never being
  rendered in two places in the same tab at once] → true today since the
  index and create page are mutually exclusive views in a single tab;
  revisit if a future change ever shows both simultaneously (e.g. a
  split-pane layout).
- [`hw-combobox:selection`/`removal` are the gem's internal event names,
  not documented as public API] → same category of risk already accepted
  for `--hw-combobox-width` in the default-product-quantity change;
  confirmed directly from the installed gem's source rather than assumed.
- [Frame-only `edit.html.erb` response (`layout: false`) means directly
  visiting `/pending_products/:id/edit` in a browser renders an unstyled,
  shell-less fragment] → acceptable since nothing in the app links there
  directly; only the modal's frame ever requests it.

## Migration Plan

Additive only: new table is untouched, new routes/controller/views, one
new CSS token pair, one sidebar link change. No data migration, no
rollback concerns beyond reverting the commit.
