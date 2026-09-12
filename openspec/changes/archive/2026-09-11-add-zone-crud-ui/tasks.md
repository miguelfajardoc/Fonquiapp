## 1. Routes and controller

- [x] 1.1 Add `resources :zones, except: [:show]` to `config/routes.rb` and verify `bin/rails routes -g zone` lists index/new/create/edit/update/destroy and no `show`/`zone#show` route
- [x] 1.2 Add `ZonesController` (`index`, `new`, `create`, `edit`, `update`, `destroy`) with strong params (`params.require(:zone).permit(:name)`) and verify `bin/rails routes -g zone` resolves each action to `ZonesController`
- [x] 1.3 Implement `create`/`update` to re-render `new`/`edit` (422) with `@zone` on validation failure, and redirect to `zones_path` with a success flash on save; verify with a controller/request test covering a blank-name create and a duplicate-name update
- [x] 1.4 Implement `destroy` to redirect to `zones_path` with a success flash when `zone.destroy` returns true, and with a flash built from `@zone.errors.full_messages` when it returns false; verify with a request test that destroys a zone with an associated client and asserts the zone still exists and the flash is present

## 2. Color tokens

- [x] 2.1 Add the light/dark CSS custom properties and `@theme` mapping (`bg`, `surface`, `surface-2`, `text`, `text-muted`, `border`, `accent`, `accent-contrast`) to `app/assets/tailwind/application.css` per design.md's token table, and verify `bin/rails tailwindcss:build` (or the dev watcher) compiles without error and generates `bg-accent`/`text-text`/etc. utility classes

## 3. Layout flash support

- [x] 3.1 Add a flash partial rendered from `app/views/layouts/application.html.erb` (styled with the new tokens), without adding a sidebar or topbar, and verify a controller action that sets `flash[:notice]` or `flash[:alert]` renders that message on the next page

## 4. Views

- [x] 4.1 Add `app/views/zones/_form.html.erb` with a single `name` field, a submit button labeled "Crear" for a new record and "Actualizar" for a persisted one, and a "Cancelar" link to `zones_path`; verify by rendering it from both `new` and `edit`
- [x] 4.2 Add `app/views/zones/new.html.erb` and `app/views/zones/edit.html.erb` wrapping the shared form with a heading; verify both routes render 200 and the submit button label differs between them
- [x] 4.3 Add `app/views/zones/index.html.erb`: a "Crear zona" button above a 2-column table (Nombre / Acciones) listing every zone with Editar and Eliminar controls per row; verify a request test asserts each seeded zone's name and its Editar link appear
- [x] 4.4 Style the form, table, and buttons (primary vs. outlined per design.md) using only the tokens from 2.1; verify by inspecting rendered HTML/CSS classes for `bg-accent`, `border-border`, etc. (no hard-coded hex values in the views)

## 5. Delete confirmation modal

- [x] 5.1 Add a single `<dialog>`-based confirmation modal to `zones/index.html.erb` with "¿Estás seguro?" copy, a Cancelar control, and a `DELETE` form/button targeting the zone; verify it renders once regardless of zone count
- [x] 5.2 Add a Stimulus controller (e.g. `modal_controller.js`, registered in `app/javascript/controllers/index.js`) that opens the dialog via `showModal()` when a row's Eliminar button is clicked, sets the dialog's zone name and delete-form target from that button's data attributes, and closes the dialog on Cancelar or the dialog's `cancel` event; verify manually in the browser (or a system/Capybara test) that clicking Eliminar opens the modal without submitting, Cancelar closes it with the zone intact, and confirming submits the delete request for the correct zone
- [x] 5.3 Verify end-to-end: with a zone that has no associated records, confirming deletes it and returns to the index without it; with a zone that has an associated client, confirming leaves it in place and shows the blocked-deletion flash from 1.4

## 6. Spec validation

- [x] 6.1 Run `openspec validate add-zone-crud-ui --strict` and fix any reported issues
