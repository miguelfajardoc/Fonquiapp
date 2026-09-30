## 1. Routes and controller

- [x] 1.1 Add `resources :clients` to `config/routes.rb` and verify `bin/rails routes -g client` lists all seven RESTful actions resolving to `ClientsController`
- [x] 1.2 Add `ClientsController` (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`) with strong params (`params.expect(client: [:name, :address, :url, :phone, :zone_id])`)
- [x] 1.3 Implement `create`/`update` to re-render `new`/`edit` (422) with `@client` on validation failure, and redirect to `clients_path` with a success flash on save; verify with a request test covering a blank-name create and a create/update with no zone selected
- [x] 1.4 Implement `destroy` to redirect to `clients_path` with a success flash when `client.destroy` returns true, and with a flash built from `@client.errors.full_messages` when it returns false; verify with a request test that destroys a client with an associated ordering record and asserts the client still exists and the flash is present

## 2. Shared delete-confirmation dialog

- [x] 2.1 Extract the `<dialog>` + Cancelar/Eliminar markup from `zones/index.html.erb` into `app/views/shared/_confirm_dialog.html.erb` (same `modal_controller.js` data attributes/targets, generalized copy dropping "la zona"), add `m-auto` to the dialog element to fix it rendering in the top-left corner instead of centered, and update `zones/index.html.erb` to render the shared partial; verify the existing Zone request specs (per-row delete, blocked-delete flash) still pass unchanged
- [x] 2.2 Move the dialog copy into a shared locale key (e.g. `shared.confirm_dialog`) in `config/locales/es.yml`, removing the old `zones.index.modal.*` keys once unused

## 3. Client views: index and row navigation

- [x] 3.1 Add `app/views/clients/index.html.erb`: a "Crear cliente" button above a table (Nombre, Dirección, Ubicación, Teléfono, Zona, Acciones) listing every client with a per-row Eliminar control (using the shared confirm dialog) and no other visible action in that column; verify a request test asserts each seeded client's name, address, url, phone, and zone name appear
- [x] 3.2 Add a Stimulus controller (`row_controller.js`) that navigates to a data-provided URL when a `<tr>` is clicked, except when the click originates inside an element marked to skip (the Eliminar cell), and wire it onto each row in `clients/index.html.erb`; verify manually (or via a system/Capybara test) that clicking a row's name/address/etc. navigates to that client's `show` page, while clicking Eliminar opens the confirmation dialog instead
- [x] 3.3 Style the index table using only the existing tokens (`bg-accent`, `border-border`, etc., no hard-coded hex values), matching the Zone index's look

## 4. Client views: show, new, edit, form

- [x] 4.1 Add `app/views/clients/show.html.erb` displaying name, address, url, phone, and zone name, with Editar (link to edit) and Eliminar (shared confirm dialog) controls at the end; verify a request test asserts all five fields and both controls appear
- [x] 4.2 Add `app/views/clients/_form.html.erb` with fields for name, address, url ("Ubicación"), phone, and a zone dropdown (`form.collection_select :zone_id, Zone.order(:name), :id, :name`, `id: "client_zone_select"`), a submit button labeled "Crear"/"Actualizar", and a "Cancelar" link to `clients_path`; verify by rendering it from both `new` and `edit`
- [x] 4.3 Add `app/views/clients/new.html.erb` and `edit.html.erb` wrapping the shared form with a heading; verify both routes render 200 and the submit button label differs between them
- [x] 4.4 Style the form and buttons using only the existing tokens, matching the Zone form's look

## 5. Inline zone creation from the client form

- [x] 5.1 Add an `in_dialog` local to `zones/_form.html.erb`: when true, render the Cancelar control as a button that closes the enclosing dialog (`data-action="click->new-zone-dialog#close"`) instead of `link_to zones_path`; verify the standalone `/zones/new` and `/zones/:id/edit` pages are unaffected (existing Zone request specs still pass)
- [x] 5.2 In `clients/_form.html.erb`, append a "+ Crear zona" sentinel option (`value="new"`) to the zone `<select>` itself (not a separate link/button) that opens a `<dialog>` containing `<turbo-frame id="new_zone_modal_form">` wrapping `render "zones/form", zone: Zone.new, in_dialog: true` — revised after review (see task 8)
- [x] 5.3 Add `new_zone_dialog_controller.js` (open the dialog when the select's sentinel option is chosen; close it on Cancelar/the dialog's `cancel` event, reverting the select to its prior value; close it on `turbo:submit-end` only when `event.detail.success` is true, keeping the newly selected zone) and wire it onto the dropdown/dialog group in `clients/_form.html.erb`
- [x] 5.4 In `ZonesController#create`, add a branch keyed on `turbo_frame_request_id == "new_zone_modal_form"`: on success, respond via `create.turbo_stream.erb` appending a `selected` `<option>` for the new zone into `#client_zone_select`; on failure, respond by replacing the `new_zone_modal_form` frame with the re-rendered `zones/_form` (`in_dialog: true`) showing `@zone.errors`; the existing non-frame create behavior is unchanged (implemented as an inline `render turbo_stream:` in the controller rather than a separate `create.turbo_stream.erb` file — same behavior, one fewer file)
- [x] 5.5 Verify end-to-end (system/Capybara test or manual): from the client new/edit form, opening the zone dialog and creating a valid new zone closes the dialog and selects that zone in the dropdown without navigating away from the client form or losing its other entered fields; submitting a blank or duplicate zone name keeps the dialog open with a validation error and leaves the client form's current zone selection unchanged — verified at the request-spec level (turbo_stream response appends the selected option, no redirect on success, frame is replaced with the error on failure); no Chrome/Chromium or Playwright is installed in this environment, so the live in-browser interaction (dialog opening/closing, JS-driven selection) was not manually driven — worth a quick manual check in a real browser before relying on this

## 6. i18n

- [x] 6.1 Add a `clients:` key to `config/locales/es.yml` (index/show/new/edit/form/flash text, plus the zone dropdown's label and the "+ Crear zona" select option) mirroring the existing `zones:` structure

## 7. Spec validation

- [x] 7.1 Run `openspec validate add-client-crud-ui --strict` and fix any reported issues

## 8. Post-review fixes

- [x] 8.1 Move the "crear zona" trigger from a separate link/button next to the zone dropdown into the dropdown itself, as an appended "+ Crear zona" option (`value="new"`); selecting it opens the dialog instead of setting `zone_id` to it, per user feedback that the trigger should be one of the select's own entries
- [x] 8.2 Fix the delete-confirmation and inline zone-creation dialogs actually rendering off-center: `app/assets/builds/tailwind.css` was stale and had never picked up the `m-auto` (and `underline`/`self-start`) utility classes added earlier, so the centering fix had no CSS behind it; rebuilt via `bin/rails tailwindcss:build` and confirmed `.m-auto{margin:auto}` is now compiled in
