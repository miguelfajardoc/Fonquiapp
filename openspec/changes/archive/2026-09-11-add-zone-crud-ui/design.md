## Context

Rails 8.1 app using the default Hotwire stack (Turbo Drive + Turbo Rails,
Stimulus, importmap) and Tailwind CSS v4 (`@import "tailwindcss"` in
`app/assets/tailwind/application.css`, no `tailwind.config.js` — theming is
CSS-first via `@theme`). `app/views/layouts/application.html.erb` is a bare
shell (no sidebar, no header chrome, no flash rendering yet). No controllers
exist yet besides `ApplicationController`; this is the first resource with a
web flow. `Zone` (`app/models/zone.rb`) already validates presence/uniqueness
of `name` and has three `has_many ... dependent: :restrict_with_error`
associations (clients, pending products, default product quantities, daily
product orders), so `zone.destroy` already returns `false` (and adds a base
error) instead of raising, when the zone is still referenced.

The referenced design artifact showed two full-screen color options (light
"Opción A" and dark "Opción B") for an ERP shell that doesn't exist in this
app yet. Per the user's direction, this change only takes the two options'
color tokens (light = Opción A, dark = Opción B) and applies them to the
Zone views; it does not build the sidebar/topbar shell shown in that mockup.

## Goals / Non-Goals

**Goals:**
- Ship a working, themed CRUD flow for `Zone` (all actions but `show`).
- Centralize every color used as a Tailwind v4 `@theme` token backed by CSS
  custom properties, so light is the default and dark applies automatically
  under `prefers-color-scheme: dark`, and so a future palette change is a
  one-file edit.
- Turn the model's existing delete-restriction into a user-visible message
  instead of an unhandled exception or a generic error page.

**Non-Goals:**
- Building the sidebar/topbar application shell from the mockup, or any
  navigation to modules that don't exist yet (Dashboard, Productos,
  Facturas, Reportes, Configuración).
- A manual light/dark toggle or any persisted theme preference — theme
  follows OS/browser preference only.
- Any change to `Zone` validations or association `dependent:` behavior —
  those already satisfy `client-directory` and `product-ordering`.

## Decisions

### Routes and controller

`resources :zones, except: [:show]` in `config/routes.rb`, backed by a
`ZonesController` with `index`, `new`, `create`, `edit`, `update`, `destroy`.
Standard strong params (`params.require(:zone).permit(:name)`). `create` and
`update` re-render `new`/`edit` (HTTP 422) with the invalid `@zone` on
validation failure, matching the spec's "keep the user on the form" scenarios.
`destroy` checks the boolean result of `zone.destroy`: on `true`, redirect to
`zones_path` with a success flash; on `false` (blocked by
`restrict_with_error`), redirect to `zones_path` with a flash built from
`@zone.errors.full_messages` so the association-in-use message the model
already attaches is what the user sees — no new error copy is invented in the
controller.

### View/partial structure

- `zones/index.html.erb`: "Crear zona" primary button above a 2-column
  table (Nombre / Acciones); one row per zone with Editar (link to `edit`)
  and Eliminar (opens the confirmation modal).
- `zones/_form.html.erb`: shared partial for `new` and `edit` — one `name`
  field, a submit button whose label is "Crear" on `new` and "Actualizar" on
  `edit` (driven by `@zone.persisted?` / `form.submit` default text is
  overridden explicitly rather than relying on Rails' pluralized default
  copy), and a "Cancelar" link back to `zones_path`.
- `zones/new.html.erb` / `zones/edit.html.erb`: thin wrappers that render the
  shared form partial with a page heading.
- A single confirmation dialog lives once on `index.html.erb` (not once per
  row) to keep the DOM small; each row's Eliminar button carries the zone's
  name and its own `zones_path(zone)` delete URL as data attributes.

### Delete confirmation as a native `<dialog>` + Stimulus, not `data-turbo-confirm`

Turbo's built-in `data-turbo-confirm` only shows the browser's native
`confirm()` — it can't be styled to match the palette. Instead:
- A `<dialog>` element (native modal semantics: focus trap, `Esc` to close,
  top-layer stacking — no extra library) holds the "¿Estás seguro?" copy, a
  Cancelar button, and a same-origin `button_to`/`form` for the actual
  `DELETE` request.
- A small Stimulus controller (`modal_controller.js`) opens the dialog via
  `showModal()` when an Eliminar button is clicked, copies that row's zone
  name into the dialog text and points the dialog's delete form at that
  row's URL, and closes it via `close()` on Cancelar or on the dialog's
  native `cancel` event (`Esc`). No confirmation state or the deletion
  itself depends on JavaScript succeeding to run the actual delete — the
  dialog only gates *when* the existing `button_to`-style DELETE form
  submits.
- Considered per-row `<dialog>` elements (no JS wiring needed beyond
  `data-turbo-confirm`-style native confirm): rejected because it can't be
  styled, and because it does not match "un modal que diga ¿Estás seguro?"
  as a single, on-brand UI element.

### Color tokens

All colors are declared once as CSS custom properties in
`app/assets/tailwind/application.css` and exposed to Tailwind utilities via
`@theme`, so classes like `bg-bg`, `bg-surface`, `text-text`,
`text-text-muted`, `border-border`, `bg-accent`, and `text-accent-contrast`
are available everywhere. Light values come from the artifact's "Opción A"
and dark values (applied under `@media (prefers-color-scheme: dark)`) from
"Opción B" — the two are otherwise structurally identical, so no new colors
are introduced:

| Token | Light (Opción A) | Dark (Opción B) |
|---|---|---|
| `bg` | `#FAF8F4` | `#121110` |
| `surface` | `#FFFFFF` | `#1B1917` |
| `surface-2` | `#FCFBF8` | `#221F1B` |
| `text` | `#1B1A18` | `#F3F0E9` |
| `text-muted` | `#797264` | `#A79E8E` |
| `border` | `#E6E0D5` | `#322D26` |
| `accent` | `#B8902E` | `#C7A233` |
| `accent-contrast` | `#1B1A18` | `#14120E` |

`accent-contrast` is the text color used on top of a solid `accent`
background (it stays a near-black shade in both modes, since `accent` itself
is light gold in both).

### Primary vs. destructive button styling stays within the same palette

The artifact's constraint is strictly white/black/gold — no red is
introduced for "destructive" actions. To still make Eliminar visually
distinct from a primary Crear/Actualizar action without adding an
off-palette color, primary actions (Crear zona, Crear/Actualizar submit,
the modal's Eliminar) are solid `bg-accent`/`text-accent-contrast`, while
secondary/neutral actions (Cancelar, the row-level Editar) are outlined
(`border-border`, transparent background, `text-text`) — the same
primary/secondary pairing the artifact itself uses for "Guardar
cliente"/"Cancelar". Eliminar in the modal is still visually set apart by
context (it only appears inside the confirmation dialog, next to the
literal "¿Estás seguro?" copy), not by a different hue.

### i18n for user-facing text

The project's existing RuboCop config enables `Rails/I18nLocaleTexts`
(default in `rubocop-rails`, never overridden), which flags literal strings
passed to `redirect_to ..., notice:/alert:` and similar. Since the app had no
real i18n setup yet (only Rails' sample `en.yml`) and this is the first
controller with user-facing text, this was resolved with the user rather
than assumed:
- `config/locales/es.yml` holds this flow's Spanish text (flash messages,
  headings, labels, button text, the modal copy), looked up via Rails' view
  and controller lazy `t(".key")` lookup.
- `config/application.rb` sets `config.i18n.default_locale = :es` and
  `config.i18n.fallbacks = [:en]`. The fallback is what keeps this
  low-risk: built-in messages this change doesn't translate (e.g.
  ActiveRecord's "has already been taken"/"can't be blank", which several
  pre-existing model specs assert in English) keep resolving in English
  automatically instead of raising or rendering a missing-translation
  placeholder, so no unrelated spec had to change.
- Alternative considered: leave the literal Spanish strings inline and
  silence the cop locally. Rejected per the user's explicit choice to
  introduce real i18n now rather than defer it.

This is the one part of this change that touches something outside the
Zone flow (`config/application.rb`, a global setting) — everything else
remains additive.

### Pinning `json` below 3.0

Manually testing the flash flow (creating/deleting a zone, then loading the
index) surfaced a pre-existing, unrelated bug: the resolved `json` gem
(3.0.2, a transitive dependency, never pinned in the Gemfile) parses with
`JSON.parse(source, **kwargs)`, but `activesupport` 8.1.3.1 still calls
`::JSON.parse(json, options)` positionally in `ActiveSupport::JSON.decode`.
That raises `ArgumentError: wrong number of arguments (given 2, expected 1)`
from any code path that decrypts a signed/encrypted cookie payload through
that method — including reading back a flash message. Nothing before this
change ever set a flash, so the app never exercised that path. Fixed by
adding `gem "json", "< 3"` to the Gemfile and re-locking, which resolves to
`json` 2.21.2; no Rails release compatible with `json` 3.x exists yet at
time of writing. This is unrelated to Zone specifically and would have hit
the first flash message any future feature set, so it's fixed here rather
than deferred.

## Risks / Trade-offs

- **Flash rendering doesn't exist yet in the layout.** `application.html.erb`
  never renders `flash` today. → This change adds a small flash partial
  rendered from the layout (still no sidebar/topbar), since the delete-block
  and save-success messages need somewhere to appear; scoped narrowly to
  flash only.
- **Single shared `<dialog>` mutated per row via data attributes** is simpler
  than N dialogs, but means the delete form's `action` URL is rewritten by
  JS on every Eliminar click. → Low risk: the controller reads the URL from
  the clicked button each time, so a stale value can't survive between
  clicks.
- **No manual theme toggle** means the flow can't be visually demoed in both
  modes without changing OS/browser settings. Accepted per the user's
  direction; a toggle can be layered on later without changing these tokens.

## Migration Plan

Mostly additive: new route, new controller, new views/partials, new
Stimulus controller, and new CSS tokens; no data migration. The one
existing-file change beyond Zone's own scope is `config/application.rb`
(default locale + fallback, see "i18n for user-facing text" above) and the
small flash partial now rendered from `application.html.erb`. Rollback is
deleting the added files/route and reverting those two touched files.
