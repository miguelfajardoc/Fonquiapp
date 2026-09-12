## Why

Every page today renders inside a bare `<main>` with no navigation chrome —
staff can only reach Zonas or Clientes by typing a URL. As more modules
(Productos and its sub-flows) get planned, the app needs a persistent
sidebar and header shell so users can move between sections, and so new
sections have an obvious place to be listed even before their own views
exist.

## What Changes

- Add a persistent two-column app shell (`app/views/layouts/application.html.erb`):
  a fixed dark sidebar on the left and the page content (with a slim header
  bar above it) on the right. Every existing page (Zonas, Clientes) renders
  inside this shell with no other visual changes.
- Sidebar top section shows the brand label "Fonquilac" (no logo asset).
- Sidebar navigation lists three top-level entries in this order: **Zonas**
  (links to `zones_path`), **Clientes** (links to `clients_path`), and
  **Productos** (not itself a link — hovering it reveals a submenu).
- Productos' submenu lists four entries — **Productos**, **Default**,
  **Pendientes**, **Orden Diaria** — none of them a link, since none of the
  underlying models (`Product`, `DefaultProductQuantity`, `PendingProduct`,
  `DailyProductOrder`) has a controller or view yet. They render as inert
  (non-clickable, visually muted) labels reserving their place in the menu
  for when those flows are built.
- The currently active top-level section (Zonas or Clientes) is visually
  highlighted in the sidebar based on the current controller.
- Sidebar bottom area (shown with a user name in the referenced design
  artifact) is left empty — no user/session model exists yet.
- Header bar shows only the current section's title (from the page's
  existing `content_for :title`); no user avatar or account menu, for the
  same reason the sidebar footer stays empty.
- Extend the centralized color tokens in `app/assets/tailwind/application.css`
  with sidebar-specific tokens (`sidebar-bg`, `sidebar-text`,
  `sidebar-text-muted`) taken from the referenced artifact's "Opción A"
  (light mode) and "Opción B" (dark mode) sidebar colors, following the same
  light-default/dark-via-`prefers-color-scheme` pattern already used for
  every other token.

## Capabilities

### New Capabilities
- `app-shell`: the persistent sidebar + header navigation chrome every page
  renders inside — its structure, its nav entries and their targets (or
  lack of one), active-section highlighting, and what is deliberately left
  blank pending future work (user identity).

### Modified Capabilities
- None. This only adds chrome around existing pages; it does not change
  any existing routes, controllers, or model-level requirements.

## Impact

- **Layout**: `app/views/layouts/application.html.erb` gains the sidebar +
  header shell wrapping `yield`.
- **Views**: new `app/views/layouts/_sidebar.html.erb` and
  `app/views/layouts/_header.html.erb` partials.
- **Styles**: `app/assets/tailwind/application.css` gains sidebar color
  tokens; no new dependency.
- **i18n**: `config/locales/es.yml` gains a `nav` namespace for the sidebar
  labels ("Zonas", "Clientes", "Productos", "Default", "Pendientes", "Orden
  Diaria").
- **Routes/Controllers/Models**: none changed. `Product`,
  `DefaultProductQuantity`, `PendingProduct`, and `DailyProductOrder`
  remain without controllers or views.
