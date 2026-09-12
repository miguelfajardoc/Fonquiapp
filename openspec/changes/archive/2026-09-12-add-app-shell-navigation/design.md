## Context

See `proposal.md` - Why/What Changes. `app/views/layouts/application.html.erb`
is currently a bare shell: `<body class="bg-bg text-text">` wrapping a
centered `<main>` that renders the flash partial and `yield`, with no
sidebar or header (this was an explicit non-goal of `add-zone-crud-ui`,
which only pulled color tokens out of the same reference artifact). Every
page already sets `content_for :title` (used today only for `<title>`) and
already renders inside `<main class="container mx-auto mt-28 px-5 ...">`.
Tailwind v4 is CSS-first (`@theme` in `app/assets/tailwind/application.css`,
no config file); color tokens for `bg`/`surface`/`text`/`accent`/etc.
already exist there and switch between the artifact's "Opción A" (light,
default) and "Opción B" (dark, `prefers-color-scheme: dark`) values. No
user/session/auth model exists in the app yet, and no `ProductsController`
or views exist for `Product`, `DefaultProductQuantity`, `PendingProduct`,
or `DailyProductOrder` (confirmed via `app/controllers` and `app/views`).

## Goals / Non-Goals

**Goals:**
- Wrap every page in a persistent sidebar + header shell using only the
  project's existing stack (ERB layout/partials, Tailwind v4 tokens, plain
  CSS hover) — no new dependency.
- Extend the existing token system (rather than hard-coding colors) so the
  sidebar keeps following the same light/dark-via-OS-preference pattern as
  the rest of the app.
- Make the Productos hover submenu discoverable without JavaScript, since
  it is pure disclosure UI with no state to manage.

**Non-Goals:**
- Any mobile/responsive collapsing behavior for the sidebar (hamburger
  menu, off-canvas drawer). The rest of the app has no responsive layout
  work yet (`container mx-auto ... px-5` is the extent of it); this change
  keeps the same desktop-first assumption and a fixed-width sidebar.
- Building `ProductsController` or any view for `Product`,
  `DefaultProductQuantity`, `PendingProduct`, or `DailyProductOrder` —
  confirmed out of scope with the user; all four submenu entries stay
  inert.
- A touch/keyboard-accessible alternative to hover for revealing the
  Productos submenu. Out of scope for this pass since the submenu has no
  functional destinations yet; revisit once at least one entry links
  somewhere.
- Any user avatar, name, or account menu — no session model exists.

## Decisions

### Layout: two-column flex shell in `application.html.erb`

`application.html.erb`'s `<body>` becomes a `flex` row of two children: the
sidebar partial (`layouts/_sidebar`, fixed width, full viewport height) and
a `flex flex-col` column holding the header partial (`layouts/_header`)
above the existing `<main>` (still rendering the flash partial and
`yield`, minus the `mt-28` used previously to clear a nonexistent fixed
header — the real header now occupies that space in-flow). This keeps the
change additive: no existing view template changes, since they all render
through `yield` unchanged.

Alternative considered: a fixed/sticky sidebar with `position: fixed` and a
content `margin-left`. Rejected as unnecessary complexity — an ordinary
flex row with the sidebar's own `min-h-screen` achieves the same persistent
look with less positioning math, matching how the reference artifact's
mockup is structured (`display:flex` on the outer screen container).

### Sidebar navigation structure and Productos submenu via CSS-only hover

The sidebar is a `<nav>` with three top-level items:
- "Zonas" → `link_to zones_path`
- "Clientes" → `link_to clients_path`
- "Productos" → a non-link container (`<div>`, not `<a>`) wrapping the
  label and, immediately after it, the submenu list. Tailwind's `group` /
  `group-hover:block` (submenu default `hidden`) shows the submenu when
  the pointer is over the Productos container — pure CSS, no Stimulus
  controller, since there is no state to persist and no click behavior to
  intercept (unlike the existing delete-confirmation modal, which needed
  Stimulus because it reacts to a click and mutates a dialog's target
  URL).
- The four submenu entries ("Productos", "Default", "Pendientes", "Orden
  Diaria") render as `<span>`/non-interactive text in a muted style, not
  `<a>` or `<button>`, so they cannot be tabbed to or activated — matching
  "no tendrán link" precisely rather than rendering disabled-looking links
  that still appear focusable.

Alternative considered: a Stimulus-driven dropdown (click-to-open, like
the delete modal). Rejected because the user explicitly asked for
hover-to-reveal, and hover needs no JavaScript at all here.

### Active-section highlighting via `controller_name`

The sidebar partial compares Rails' `controller_name` (or
`controller_path`) against each top-level entry's owning controller
(`"zones"`, `"clients"`) to add the active/highlighted classes — no new
helper method, since only two controllers exist to check today. Productos
has no controller to match against, so it never receives the active
style (consistent with "Productos entry has no direct destination" in the
spec).

### Header shows only the page title, no breadcrumb or avatar

The reference artifact's header includes a breadcrumb ("Clientes / Nuevo
cliente") and a user-initials avatar. This change's header renders only
the current page's existing `content_for :title` value (already set by
every view, e.g. `t(".title")` → "Zonas") as plain text — no breadcrumb
trail (no page in the app is nested more than one level deep today, so a
breadcrumb would just repeat the section name) and no avatar (no
user/session model, same reason the sidebar's bottom user block is left
empty per the proposal).

### Sidebar color tokens extend the existing token table

Three new tokens are added to `app/assets/tailwind/application.css`
alongside the existing ones, sourced from the reference artifact the same
way `add-zone-crud-ui` sourced the others (Opción A = light default,
Opción B = dark under `prefers-color-scheme: dark`):

| Token | Light (Opción A) | Dark (Opción B) |
|---|---|---|
| `sidebar-bg` | `#16140F` | `#0A0908` |
| `sidebar-text` | `#DAD5C8` | `#E8E2D2` |
| `sidebar-text-muted` | `#8B8577` | `#8A8272` |

The sidebar stays visually dark in both modes (this matches the artifact:
both options use a near-black sidebar), while the rest of the shell
continues to switch between light and dark via the existing `bg` /
`surface` / `text` tokens. The active nav item reuses the existing
`accent` token for its text/icon color (as in the artifact), on top of a
low-opacity white overlay for its background rather than a new token,
since Tailwind's arbitrary-value opacity utilities (`bg-white/5`) cover
that without adding another custom property.

### i18n

Sidebar/header labels go under a new `nav:` key in `config/locales/es.yml`
(`nav.brand`, `nav.zones`, `nav.clients`, `nav.products`,
`nav.products_default`, `nav.products_pending`, `nav.products_daily_order`),
following the existing lazy-lookup convention used by `zones`/`clients`
(here looked up with the explicit key since the partial isn't itself a
controller view, e.g. `t("nav.zones")`).

## Risks / Trade-offs

- **Hover-only submenu is unreachable by keyboard/touch.** Accepted for
  now since none of its four entries lead anywhere yet; the moment a
  first entry gets a real view, this should be revisited (e.g. `:focus-within`
  in addition to `:hover`, or a small Stimulus toggle) — tracked as a
  known gap, not solved here.
- **Two non-interactive elements share the same label "Productos"** (the
  top-level entry and the first submenu entry) exactly as the user
  specified. Slightly redundant visually, but changing it would deviate
  from the given menu structure.
- **Removing `mt-28` from `<main>`** changes existing pages' vertical
  spacing now that a real in-flow header exists. Low risk: it was a
  fixed offset compensating for a header that didn't exist; the new
  header's own padding replaces that spacing.

## Migration Plan

Purely additive/structural: new `_sidebar`/`_header` partials, edits to
`application.html.erb` (structure only, no content removed besides the
now-unneeded `mt-28`), new CSS tokens, new locale keys. No routes,
controllers, or models change. Rollback is reverting the layout file and
deleting the two new partials and the added tokens/locale keys.
