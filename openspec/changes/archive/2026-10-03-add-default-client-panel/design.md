## Context

See proposal.md (Why). Patterns this change copies from Pendientes:

- **New page**: `pending_products/new.html.erb` wraps the form and a
  `turbo_frame_tag "pending_product_client_panel"` in a
  `pending-product-client-filter` controller. On `hw-combobox:selection` /
  `hw-combobox:removal` it reloads the panel frame from the current URL with
  `client_id` set or removed. `load_client_panel` loads the client's records.
- **Create**: responds with Turbo Streams. It replaces the client list
  (`dom_id(client, :pending_products)`) and replaces `#pending_product_form`
  with a fresh form that keeps the client. On errors it replaces the form with
  the errors (422).
- **Edit modal**: the `pending-product-edit-modal` controller (`open` sets the
  modal frame's `src` and calls `showModal()`, `close`, and `submitEnd`
  closes on success) plus `shared/_pending_product_edit_modal` (a `<dialog>`
  holding `turbo_frame_tag "pending_product_edit_modal"`). `edit` renders
  without a layout. `update` replaces `dom_id(record)` with `_row` or
  `_panel_item`, chosen by `params[:context]` (`table`/`panel`). Errors
  re-render `edit` (422) inside the frame.
- **Delete**: `destroy` responds `turbo_stream.remove(dom_id)` or falls back
  to the HTML redirect. The shared confirm dialog's form lives outside every
  frame.

Current Default code:
- The form has a zone select plus a zone-scoped client combobox in
  `turbo_frame_tag "client_combobox"`, reloaded by `client-zone-filter` with
  `zone_id` swapped in.
- `create`, `update`, and `destroy` redirect to the index. `edit` is a full
  page that reuses `_form`.
- The index renders rows inline inside `turbo_frame_tag
  "default_product_quantities"`, with an Editar link (`_top`) and a delete
  button.
- Unique index on `[product_id, client_id, zone_id]`.

## Goals / Non-Goals

**Goals:**
- One shared implementation of the edit modal and the client panel reload,
  used by Pendientes and Default.
- Default new page: panel, stay after create, modal edit, in-place delete.

**Non-Goals:**
- No change to the zone → client selection in the Default creation form
  (user decision).
- No zone or client editing for existing defaults (user decision: modal edits
  product and quantity only).
- No changes to Pendientes behavior, filters, or pagination.

## Decisions

### 1. Generalize the two Pendientes controllers instead of copying them

- `pending_product_edit_modal_controller.js` becomes `edit_modal_controller.js`
  (`edit-modal`). The logic is already generic (targets `dialog` and
  `frame`).
- `pending_product_client_filter_controller.js` becomes
  `client_panel_filter_controller.js` (`client-panel-filter`). `reload` reads
  `event.detail?.value`. When it is missing (for example a zone `change`
  event), it removes `client_id`, which returns the panel to the
  choose-a-client prompt.
- `shared/_pending_product_edit_modal.html.erb` becomes
  `shared/_edit_modal.html.erb` with a `frame_id` local. Pendientes passes
  `"pending_product_edit_modal"`. Default passes
  `"default_product_quantity_edit_modal"`.
- Update every Pendientes reference (`index`, `new`, `edit`, `_actions`) to
  the new names. Pendientes request specs and a headless-browser run guard
  against regressions.

*Alternative*: copy both controllers for Default. That gives two near-identical
files, and the next screen would add a third.

### 2. Default new page structure

```
<div data-controller="modal edit-modal">
  <h1>Nuevo default</h1>                       (form pages keep titles)
  <div data-controller="client-panel-filter"
       data-action="hw-combobox:selection->client-panel-filter#reload
                    hw-combobox:removal->client-panel-filter#reload">
    _form (id="default_product_quantity_form")
       zone select: change->client-zone-filter#reload change->client-panel-filter#reload
    turbo_frame_tag "default_product_quantity_client_panel" (client-panel-filter target)
      _client_panel -> heading + _client_default_list (id = dom_id(client, :default_product_quantities))
  </div>
  shared/confirm_dialog, shared/edit_modal(frame_id: "default_product_quantity_edit_modal")
</div>
```

- `new` loads `@selected_client` from `params[:client_id]` and
  `@client_defaults` (that client's records, ordered by product name). It
  also keeps `zone_id` from params for the form.
- The panel list uses `_panel_item` rows (`dom_id(record)`, product,
  quantity, and `_actions` with `context: "panel"`), styled like the
  Pendientes panel grid.

### 3. Create, update, and destroy respond with Turbo Streams

- `create` success:
  - Replace `dom_id(client, :default_product_quantities)` with the refreshed
    list.
  - Replace `#default_product_quantity_form` with `_form` for
    `DefaultProductQuantity.new(zone_id:, client_id:)`. The combobox then
    shows the same client, and product and quantity are blank.

  Failure: replace the form with the record and its errors (422).
- `edit`: `render layout: false`. `edit.html.erb` becomes
  `turbo_frame_tag "default_product_quantity_edit_modal"`. It holds a heading,
  the zone and client names as read-only text, a form with the product select
  and quantity field (URL keeps `context`), and Cancel
  (`edit-modal#close`) / Actualizar.
- `update`: permits only `product_id` and `quantity`
  (`params.expect(default_product_quantity: %i[product_id quantity])`), so
  zone and client cannot change even with a crafted request.
  - Success: `turbo_stream.replace(dom_id(record), partial: row_partial)`,
    where `row_partial` is `_panel_item` for `context=panel` and `_row`
    otherwise.
  - Failure: re-render `edit` (422) inside the modal frame.
  - Uniqueness on `[product_id, client_id, zone_id]` still guards duplicates.
- `destroy`: `respond_to` with `turbo_stream.remove(dom_id(record))`, and
  keep the HTML redirect as the fallback. Like Pendientes, an index delete
  now removes the row in place, with no flash or reload.

### 4. Index uses a shared `_row` partial and opens the modal

- Extract the table row to `default_product_quantities/_row.html.erb` with
  `id="<%= dom_id(record) %>"`. The table and `update` streams render it.
- `_actions.html.erb` (shared by `_row` and `_panel_item`): an Editar
  `<button>` (`edit-modal#open`, URL `edit_..._path(record, context:)`)
  plus the existing delete button. The Editar link with `_top` from
  `fix-index-edit-links` is replaced, because the modal frame sits outside
  the table frame, as on Pendientes.
- The index root gets `data-controller="modal edit-modal"` and renders
  `shared/edit_modal`.

## Risks / Trade-offs

- [Renaming shared Stimulus controllers can break Pendientes silently: a
  missing controller means a dead button, not an error page.] → Grep for every
  old name, then run Pendientes request specs plus the headless-browser flow
  (edit modal, save, panel reload) after the rename.
- [Index delete no longer shows the "Default eliminado." flash.] → This
  matches Pendientes. The row disappearing is the feedback. The HTML
  fallback still flashes.
- [After a create, the hotwire combobox must re-render with the client
  preselected.] → `Client#to_combobox_display` already exists (Pendientes
  relies on it). Verify in the browser that the client stays shown.
- [A zone change fires two reloads (combobox frame and panel frame).] →
  Both are cheap GETs of the same page and independent of each other.

## Migration Plan

No schema changes. Deploy the code. Rollback is a code revert.
