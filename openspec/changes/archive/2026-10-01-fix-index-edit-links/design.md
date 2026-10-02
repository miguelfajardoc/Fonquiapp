## Context

See proposal.md (Why). Findings from the investigation:

- `products/index.html.erb` and `default_product_quantities/index.html.erb`
  render `link_to t(".edit"), edit_*_path(...)` inside
  `turbo_frame_tag "products"` and `"default_product_quantities"`. By
  default, Turbo scopes a link inside a frame to that frame. The development
  log shows the edit page rendered `within layouts/turbo_rails/frame` (a
  frame request). In headless Chromium, Turbo throws "The response (200) did
  not contain the expected `<turbo-frame id="products">`" and shows "Content
  missing".
- Other links inside table frames are already safe:
  - Client rows navigate with `Turbo.visit` (top level) from
    `row_controller.js`.
  - Delete buttons open `shared/_confirm_dialog`, which is rendered outside
    the frame.
  - The daily-order download link has `data-turbo="false"`.
  - Zonas and Rutas have no table frame.
- Pendientes: "Editar" is a `<button>` that sets the `src` of the separate
  `pending_product_edit_modal` frame, which sits outside the table frame. In
  headless Chromium against the current code, the modal opens (request
  header `Turbo-Frame: pending_product_edit_modal`), saving closes it and
  replaces the row, and "Entregar" replaces the row. It also works in the
  default "Pendiente" view. The user's report was most likely a stale page
  from before a server or JS reload.
- Client rows have `data-controller="row"`. `row#visit` skips clicks inside
  `[data-row-target="skip"]`, which is the actions cell.

## Goals / Non-Goals

**Goals:**
- Per-row edit links open the full edit page from any filtered or paginated
  index.
- Add a per-row "Editar" on the client index.

**Non-Goals:**
- No change to the Pendientes modal flow (not reproducible, see Context).
- No change to how pagination or filters target the table frames.

## Decisions

### 1. `data-turbo-frame="_top"` on each in-frame edit link

Add `data: { turbo_frame: "_top" }` to the edit `link_to` on Productos and
Default, and to the new client edit link. Only these links break out of the
frame, so pagination links and filter submits keep refreshing just the
table.

*Alternative*: `target: "_top"` on the whole table frame. Rejected because
it would turn every pagination click into a full-page visit and give up the
frame-only refresh the filters rely on. Each future in-frame link would also
silently change behavior.

### 2. Client "Editar" inside the skipped actions cell

Put `link_to t(".edit"), edit_client_path(client)` with the frame break-out
next to the existing "Eliminar" button, in the actions `<td>`, which already
has `data-row-target="skip"`. The click opens the edit form and does not
trigger `row#visit`. Wrap both controls in `div.flex.gap-3` and use the same
button styling as the other indexes. Add `clients.index.edit: "Editar"`.

### 3. Verification

- Request specs assert that every edit link inside a table frame carries
  `data-turbo-frame="_top"`. This pins the regression without a browser.
- A scripted headless-browser check (Playwright plus Chromium, set up in the
  session scratchpad, not added to the project) clicks "Editar" on
  Productos, Default, Clientes, and Pendientes. It asserts that the edit page
  or modal shows and that no `frame-missing` error is raised. The project
  gains no browser-test dependency.

## Risks / Trade-offs

- [Future in-frame links can hit the same problem.] → The request specs make
  the pattern visible. Any new link in a table frame should add the
  `_top` target.
- [The Pendientes report could have a cause not reproduced headless.] → The
  browser check runs the user's exact flow. If the user still sees it after
  reloading, capture the browser console error and open a follow-up.

## Migration Plan

View-only change. Deploy the code. Rollback is a code revert.
