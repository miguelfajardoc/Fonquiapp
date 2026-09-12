## Why

Zone records can only be managed today through the Rails console or seeds — there
is no web flow for staff to list, create, edit, or remove a zone. The `Zone`
model, its validations, and its delete-restriction rules already exist
(`client-directory`, `product-ordering`), but nothing in `app/controllers` or
`app/views` exposes them yet. This change adds the first web CRUD flow in the
app, so it also establishes the shared, centralized color tokens (light
default / dark via OS preference) that later flows will reuse.

## What Changes

- Add `resources :zones, except: [:show]` routes and a `ZonesController` with
  `index`, `new`, `create`, `edit`, `update`, and `destroy` actions.
- Add a `zones/index` view: a 2-column table (Name, Actions) with Edit and
  Delete buttons per row, and a "Crear zona" button above the table.
- Add a shared `zones/_form` partial (used by `new` and `edit`) with a single
  `name` field, a submit button labeled "Crear" on `new` and "Actualizar" on
  `edit`, and a "Cancelar" link back to the index.
- Add a delete-confirmation modal ("¿Estás seguro?" with Cancelar/Eliminar)
  shown when Delete is pressed on the index, implemented as a Stimulus
  controller so no extra gem is required.
- Surface a flash error on the index when deleting a zone is blocked because
  clients or ordering records still reference it (the model already enforces
  this via `restrict_with_error`), instead of a generic/unhandled error page.
- Centralize the color palette adapted from the referenced design artifact as
  Tailwind v4 `@theme` tokens (`app/assets/tailwind/application.css`): light
  values by default, dark values under `prefers-color-scheme: dark`, so every
  color used in the Zone views (and future flows) is defined in one place.
- Style the index table, form inputs/buttons, and modal using those tokens.
  The existing bare `application.html.erb` layout is kept as-is (no sidebar or
  topbar shell); only the content styling is added.

## Capabilities

### New Capabilities
- `zone-management`: the web CRUD flow for zones — routes, controller
  behavior (including the show exclusion and the delete-restriction flash),
  and the index/create/edit/delete-modal views.

### Modified Capabilities
- None. `client-directory` and `product-ordering` already specify that a
  zone referenced by clients or ordering records cannot be deleted; this
  change only exposes that existing rule through a web flow and does not
  change the rule itself.

## Impact

- **Routes**: `config/routes.rb` gains `resources :zones, except: [:show]`.
- **Controllers**: new `app/controllers/zones_controller.rb`.
- **Views**: new `app/views/zones/index.html.erb`, `new.html.erb`,
  `edit.html.erb`, `_form.html.erb`, and a delete-confirmation modal
  partial/template.
- **JavaScript**: new Stimulus controller
  (`app/javascript/controllers/modal_controller.js`) for the delete modal;
  auto-registered like every other controller in
  `app/javascript/controllers/` (no manual wiring needed).
- **Styles**: `app/assets/tailwind/application.css` gains `@theme` color
  tokens; no new dependency (Tailwind v4 and Stimulus are already present).
- **Layout**: `app/views/layouts/application.html.erb` gains a rendered
  flash partial (no sidebar/topbar added in this change).
- **Dependencies**: `Gemfile`/`Gemfile.lock` pin `json` to `< 3` (resolves
  to 2.21.2). The previously unpinned transitive `json` 3.0.2 broke
  `ActiveSupport::JSON.decode` (used to read back any signed/encrypted
  cookie, flash included) under `activesupport` 8.1.3.1 — see design.md.
- **i18n**: new `config/locales/es.yml` for this flow's user-facing text;
  `config/application.rb` sets the app's default locale to `:es` with a
  fallback to `:en` for any message this change doesn't translate (see
  design.md). This is app-wide, not scoped to Zone, since default locale is
  a single global setting.
