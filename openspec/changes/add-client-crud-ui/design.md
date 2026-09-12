## Context

See `proposal.md` for motivation. Builds directly on `add-zone-crud-ui`
(not yet archived, but fully implemented and tested): `ZonesController`,
`zones/_form`, the shared color tokens in
`app/assets/tailwind/application.css`, the flash partial rendered from
`application.html.erb`, and the delete-confirmation `<dialog>` +
`modal_controller.js` pattern all already exist and are reused as-is or
extracted, not reinvented. `Client` (`app/models/client.rb`) already
validates presence of `name`, `belongs_to :zone` (required by default under
Rails' `belongs_to_required_by_default`), and has three
`dependent: :restrict_with_error` associations (`pending_products`,
`default_product_quantities`, `daily_product_orders`), so `client.destroy`
already returns `false` (with a base error) instead of raising when the
client is still referenced — exactly the pattern `Zone#destroy` already
relies on.

Two assumptions made explicit here (call them out if either is wrong before
`/opsx:apply`, since both are cheap to reverse but change observable
behavior):
- **Index "acciones" = Crear + Eliminar only, not Editar.** The request lists
  the index's actions as "crear y eliminar" and separately says Editar lives
  on the detail (`show`) view's action row. Read literally, the index row
  itself only needs a delete control (matching the spec above); reaching
  Editar goes through the row click → `show` → Editar.
- **Create/update success redirects to `clients_path` (the index), not to
  the new/updated client's `show` page.** This matches the Zone flow's
  existing convention (create/update → index) and keeps Cancelar and
  save both landing in the same place. `show` is only reached by choosing a
  client from the index.

## Goals / Non-Goals

**Goals:**
- Ship a working Client CRUD flow (routes, controller, index/show/new/edit
  views) styled with the existing tokens, matching the Zone flow's
  conventions so the two feel like one system.
- Make the delete-confirmation dialog a genuinely shared component (one
  partial + one Stimulus controller, no per-model duplication) instead of
  living embedded in `zones/index.html.erb`, and fix its centering.
- Let a zone be created from inside the Client form without losing the
  in-progress Client form (no full-page navigation away and back).

**Non-Goals:**
- Any change to `Client` or `Zone` model validations or `dependent:`
  behavior — those already satisfy `client-directory`.
- A general-purpose "create any related record inline" mechanism. This
  change wires the zone-from-client case specifically; a third instance of
  the same need can decide then whether to generalize.
- Archiving `add-zone-crud-ui` (out of scope here; this change only reuses
  and lightly touches Zone's views/controller).

## Decisions

### Routes and controller

`resources :clients` (all seven actions, unlike Zone's `except: [:show]`),
backed by `ClientsController` with `index`, `show`, `new`, `create`, `edit`,
`update`, `destroy`. Strong params: `params.expect(client: [:name, :address,
:url, :phone, :zone_id])`, following `ZonesController`'s use of
`params.expect`. `create`/`update` re-render `new`/`edit` (422) with the
invalid `@client` on failure; `destroy` follows `ZonesController#destroy`'s
exact pattern (redirect with success flash on `true`, redirect with a flash
built from `@client.errors.full_messages` on `false`).

### Row click navigates to `show`, delete control does not

Each `<tr>` gets `data-action="click->row#visit" data-row-url-param="<%=
client_path(client) %>"` and a small Stimulus controller (`row_controller.js`)
that calls `Turbo.visit(url)` — except when the click originated inside an
element carrying `data-row-target="skip"` (added to the Eliminar button's
`<td>`), which the controller checks via
`event.target.closest("[data-row-target='skip']")` before navigating. This
avoids the invalid-HTML problem of nesting a `<button>`/`<form>` inside an
`<a>`, and avoids making the whole row an `<a>` (which Tailwind and the
existing table styling don't assume). Considered wrapping row cells in a
`link_to ..., class: "contents"`: rejected because the Eliminar button (a
`button_to`-style form) still cannot legally nest inside that anchor, so the
click-target-checking approach is needed either way — doing it uniformly via
Stimulus is simpler than mixing both techniques.

### Shared delete-confirmation dialog

The `<dialog>` + Cancelar/Eliminar markup currently embedded in
`zones/index.html.erb` moves to `app/views/shared/_confirm_dialog.html.erb`,
still driven by the existing `modal_controller.js` unchanged (it already
takes the entity name and delete URL as Stimulus params, so it has no
Zone-specific logic to begin with). Both `zones/index.html.erb` and
`clients/index.html.erb` render `render "shared/confirm_dialog"` inside a
`data-controller="modal"` wrapper, each row passing its own
`data-modal-name-param`/`data-modal-url-param`. The copy changes from
"¿Estás seguro que deseas eliminar la zona `<name>`?" to "¿Estás seguro que
deseas eliminar `<name>`?" (dropping the now model-specific "la zona") so one
string works for both models; both locale files' `shared.confirm_dialog` key
holds it once.

**Centering fix**: Tailwind's preflight resets `margin: 0` on every element,
which overrides the browser's default `margin: auto` on `dialog:modal` (the
UA rule that centers a `showModal()`-opened dialog). Since Tailwind v4 puts
utilities in a later cascade layer than preflight's base layer, adding the
`m-auto` utility class to the dialog element restores centering without
touching preflight globally (which could have other, unrelated effects).
Note: the first pass added the class but never actually saw it centered,
because `app/assets/builds/tailwind.css` (gitignored, regenerated by
`bin/rails tailwindcss:build`/`tailwindcss:watch`) was stale and simply had
no `.m-auto` rule yet — the class name in the markup had no CSS behind it.
Rebuilding it made the existing fix take effect; no markup change was
needed. Any new utility class introduced mid-session needs a rebuild (or the
watcher running) before it can be seen working.

### Client form and zone dropdown

`clients/_form.html.erb` mirrors `zones/_form.html.erb`'s structure (error
summary, labeled fields, Cancelar/submit row) with `name`, `address`, `url`
(labeled "Ubicación"), `phone` as text fields, plus a zone `<select>` with an
explicit `id: "client_zone_select"` (rather than relying on Rails' implicit
id) so the inline zone-creation response below has a stable target.

### Inline "crear zona" from the client form

Goal restated from the spec: submitting a new zone from inside the client
form closes the prompt and selects that zone, without navigating away from
the client form; an invalid submission keeps the prompt open with the error.

**Approach**: the zone `<select>` itself carries one extra option ("+ Crear
zona", `value="new"`) appended after the real zones
(`options_from_collection_for_select(...) + content_tag(:option, ...)`), so
there is no separate link or button next to the dropdown — choosing "create
a zone" is one of the dropdown's own entries. A `change` action
(`new-zone-dialog#openOnNewOption`) opens the dialog when that sentinel
value is selected, and otherwise just remembers the select's current value
(`previousValue`) so a later cancel has something real to restore. The
dialog contains a `<turbo-frame id="new_zone_modal_form">` wrapping
`zones/_form` rendered with a new local, `in_dialog: true`. When
`in_dialog` is true, the partial's Cancelar control becomes a plain button
that closes the dialog (`data-action="click->new-zone-dialog#close"`)
instead of `link_to zones_path` — linking to `/zones` would navigate the
whole page away from the in-progress client form, discarding it, so the
existing Cancelar markup can't be reused unmodified; this is the one change
to `zones/_form.html.erb` itself, gated behind the new local so the
standalone `/zones/new` and `/zones/:id/edit` pages are unaffected. Canceling
(or `Esc`) resets the select back to `previousValue` so the sentinel option
is never left selected; a successful create instead updates `previousValue`
to the newly-selected (real) zone before closing, so the new zone sticks.

**Alternative considered (first pass, corrected after review)**: a separate
"Crear zona" link/button next to the dropdown. Rejected per the user's
explicit direction that the trigger should be one of the select's own
options, not an adjacent control.

`ZonesController#create` gets one new branch, keyed on
`turbo_frame_request_id == "new_zone_modal_form"` (a `turbo-rails`-provided
check — no new request param to invent):
- **Not** that frame (existing `/zones` flow): unchanged — redirect on
  success, `render :new, status: :unprocessable_content` on failure.
- **Is** that frame, success: respond with a `create.turbo_stream.erb` that
  appends `<option selected>` (the new zone) into `#client_zone_select`.
  Setting the `selected` attribute at insertion time both selects it and
  (per how a single-select `<select>` reconciles its options) deselects
  whatever was selected before.
- **Is** that frame, failure: `render turbo_stream:
  turbo_stream.replace("new_zone_modal_form") { render partial: "zones/form",
  locals: { zone: @zone, in_dialog: true } }, status: :unprocessable_content`
  — Turbo replaces just the frame's content with the same partial, now
  showing `@zone.errors`, so the dialog stays open with the error and the
  rest of the client form (outside the frame) is untouched.

**Closing the dialog on success** is handled entirely client-side, not via a
custom Turbo Stream action: Turbo dispatches `turbo:submit-end` (bubbling up
from the form) on every submission, carrying `event.detail.success`. A small
`new_zone_dialog_controller.js` (scoped around the dropdown + link + dialog)
listens for `turbo:submit-end->new-zone-dialog#closeOnSuccess` and calls
`dialogTarget.close()` only when `detail.success` is true — so a failed
submission (which never reaches the `create.turbo_stream.erb` branch above)
leaves the dialog open by simply not closing it, with no explicit
"stay open" logic needed.

**Alternative considered**: doing the whole round-trip as hand-rolled
JSON + `fetch` from Stimulus (no Turbo Frame/Stream), parsing errors into
the modal manually. Rejected: it would duplicate `zones/_form`'s existing
error-list rendering in JavaScript instead of reusing the ERB partial as
asked ("utilizando el mismo form de zones"), and the Turbo Frame/Stream
approach needs no new response format on the controller beyond what
`turbo-rails` (already in the Rails 8 default Gemfile) provides.

### i18n

`config/locales/es.yml` gains a `clients:` key mirroring `zones:`'s
structure (`index`, `show`, `new`, `edit`, `form`, `flash`), plus the client
form's `new_zone_link`/`zone_label` strings. The shared dialog's copy moves
under a new `shared.confirm_dialog` key (both `zones/index` and
`clients/index` reference it); `zones.index.modal.*` keys are removed from
`es.yml` once nothing references them.

## Risks / Trade-offs

- **`zones/_form.html.erb` now branches on `in_dialog`.** → Kept to a single
  `if` around the Cancelar control only; every other line renders
  identically in both contexts, so the standalone Zone pages can't regress
  silently (covered by re-running the existing Zone request specs
  unchanged).
- **A non-2xx (`422`) response body still being a `turbo_stream` frame
  replace** is a slightly less common Turbo pattern than a 200. → Turbo
  processes a `turbo_stream`-typed response body regardless of status code;
  if manual testing shows otherwise, the fallback is dropping to `status:
  200` for this one branch only (still distinguishable from success by the
  presence of `zone.errors` in the re-rendered partial).
- **Row-click-to-navigate and the delete button live in the same `<tr>`.** →
  Mitigated by checking the click's target against the delete cell rather
  than relying on `stopPropagation` inside the delete button (which would
  also have to keep working if a future row gains more controls).

## Migration Plan

Additive except for the two touched Zone files: `zones/_form.html.erb`
(the `in_dialog` branch) and `zones/index.html.erb` (delete dialog markup
replaced by a render of the new shared partial — same generated HTML/data
attributes, so `modal_controller.js` and the existing Zone request specs
need no changes). `ZonesController#create` gains the frame-scoped branch
described above; its non-frame behavior is unchanged. Rollback is deleting
the new Client route/controller/views/partials/Stimulus controllers and
reverting the three touched Zone files.
