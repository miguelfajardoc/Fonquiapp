## Why

Client records can only be managed today through the Rails console or seeds —
there is no web flow for staff to list, view, create, edit, or remove a
client. The `Client` model and its validations already exist
(`client-directory`), and the Zone web CRUD flow (`add-zone-crud-ui`)
established the app's routing, controller, color-token, and delete-modal
conventions. This change adds the matching web CRUD flow for `Client`, reuses
those conventions, and extends the shared delete-confirmation modal so it can
be reused by any model's index (starting with Client) instead of living
embedded in the Zone index only.

## What Changes

- Add `resources :clients` (all seven actions, including `show` — unlike
  Zone) and a `ClientsController` with `index`, `show`, `new`, `create`,
  `edit`, `update`, and `destroy`.
- Add a `clients/index` view: a table (Nombre, Dirección, Ubicación,
  Teléfono, Zona, Acciones) with a "Crear cliente" button above it and a
  per-row Eliminar control; clicking anywhere else on a row navigates to that
  client's `show` page (editing happens from `show`, not from the index row).
- Add a `clients/show` view displaying every field, with Editar and Eliminar
  actions at the end.
- Add a shared `clients/_form` partial (used by `new` and `edit`) with fields
  for name, address, url, phone, and a Zone dropdown, plus Crear/Actualizar
  and Cancelar actions.
- Extract the delete-confirmation `<dialog>` + its Stimulus controller out of
  `zones/index.html.erb` into a shared partial so `clients/index` (and any
  future index) can reuse it as-is, and fix the dialog rendering in the
  screen's top-left corner instead of centered (a pre-existing Tailwind
  preflight side effect: `margin: 0` on all elements overrides the browser's
  default `margin: auto` centering for `<dialog>`).
- Add an inline "crear zona" flow reachable from the Client form's zone
  dropdown: a link next to the dropdown opens a modal containing the same
  Zone creation form (`zones/_form`); saving it there creates the zone,
  closes the modal, and selects the new zone in the Client form's dropdown
  without navigating away from (or losing) the in-progress Client form;
  validation errors keep the modal open and show the error, matching the
  standalone Zone form's behavior.
- Reuse the existing color tokens and form/table/button styling established
  by the Zone flow — no new tokens or design decisions.

## Capabilities

### New Capabilities
- `client-management`: the web CRUD flow for clients — routes, controller
  behavior, the index/show/new/edit views, the delete-confirmation reuse, and
  the inline zone-creation-from-client-form behavior.

### Modified Capabilities
- None. `client-directory` already specifies the `Client` record's fields,
  validations, and required zone reference; this change only exposes those
  existing rules through a web flow. The shared delete-confirmation dialog's
  extraction and visual centering fix are implementation-level changes to
  the Zone flow (no observable requirement in `zone-management`'s existing
  spec text changes — it never specified dialog placement or the partial's
  file location).

## Impact

- **Routes**: `config/routes.rb` gains `resources :clients`.
- **Controllers**: new `app/controllers/clients_controller.rb`.
- **Views**: new `app/views/clients/index.html.erb`, `show.html.erb`,
  `new.html.erb`, `edit.html.erb`, `_form.html.erb`; a new
  `app/views/zones/_modal_form.html.erb` (or equivalent) variant of the Zone
  form usable inside a dialog; new `app/views/zones/create.turbo_stream.erb`
  for the inline-creation response.
- **Shared views**: `zones/index.html.erb`'s delete-confirmation `<dialog>` +
  markup moves into a shared partial (e.g.
  `app/views/shared/_confirm_dialog.html.erb`), referenced from both
  `zones/index` and `clients/index`.
- **JavaScript**: existing `modal_controller.js` (delete confirmation) is
  reused unchanged via the shared partial; a new Stimulus controller drives
  the inline zone-creation dialog (open/close and auto-close on a successful
  Turbo form submission).
- **i18n**: `config/locales/es.yml` gains a `clients` key with this flow's
  labels, headings, and flash messages, following the existing `zones`
  structure.
- **Dependencies**: none new — reuses Turbo Frames/Streams and Stimulus,
  already part of the Rails 8 default stack used by the Zone flow.
