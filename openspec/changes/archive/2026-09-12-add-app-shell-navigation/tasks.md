## 1. Color tokens

- [x] 1.1 Add `sidebar-bg`, `sidebar-text`, and `sidebar-text-muted` CSS custom properties (light/dark pairs per design.md's token table) and their `@theme` mapping to `app/assets/tailwind/application.css`; verify `bin/rails tailwindcss:build` compiles without error and generates `bg-sidebar-bg`/`text-sidebar-text`/`text-sidebar-text-muted` utility classes

## 2. i18n

- [x] 2.1 Add a `nav:` key to `config/locales/es.yml` with `brand` ("Fonquilac"), `zones` ("Zonas"), `clients` ("Clientes"), `products` ("Productos"), `products_default` ("Default"), `products_pending` ("Pendientes"), and `products_daily_order` ("Orden Diaria"); verify `bin/rails runner 'puts I18n.t("nav.zones")'` prints "Zonas"

## 3. Sidebar partial

- [x] 3.1 Add `app/views/layouts/_sidebar.html.erb`: brand label from `t("nav.brand")`, a "Zonas" link to `zones_path` and a "Clientes" link to `clients_path` using `nav.zones`/`nav.clients`; verify by rendering any existing page and asserting both links are present with the correct `href`s
- [x] 3.2 Add the active-state check comparing `controller_name` to `"zones"`/`"clients"` and apply a distinct (accent-colored) style to the matching entry; verify with request specs that the zone index highlights Zonas but not Clientes, and the client index highlights Clientes but not Zonas (e.g. by asserting the active CSS class appears adjacent to the expected label and not the other)
- [x] 3.3 Add the "Productos" entry as a non-link container with a CSS-only (`group`/`group-hover`) submenu listing `nav.products`, `nav.products_default`, `nav.products_pending`, `nav.products_daily_order` in that order, each rendered as non-interactive text (no `<a>`/`<button>`); verify by rendering any existing page and asserting the four labels are present in order and none appears inside an `<a>` or `<button>` tag, and that "Productos" itself is not inside an `<a>` tag either

## 4. Header partial

- [x] 4.1 Add `app/views/layouts/_header.html.erb` displaying the current page's `content_for :title` value as plain text, with no avatar or account control; verify by rendering the zone index and client index and asserting each shows its own title text ("Zonas", "Clientes") in the header

## 5. Layout integration

- [x] 5.1 Update `app/views/layouts/application.html.erb` to a flex row of the sidebar partial and a flex column (header partial above the existing flash partial + `yield`), removing the now-unneeded `mt-28` from `<main>`; verify every existing request spec (`spec/requests/zones_spec.rb`, `spec/requests/clients_spec.rb`) still passes unchanged
- [x] 5.2 Manually verify in the browser: sidebar and header appear on both the zone and client sections, hovering "Productos" reveals its submenu and moving the pointer away hides it again, and no user name/avatar appears anywhere in the shell (no headless-browser tool was available in this environment; verified instead against the running dev server's actual rendered HTML for `/zones` and `/clients` with seeded data, plus the compiled Tailwind CSS confirming `.group-hover\:flex` has higher specificity than `.hidden` so the reveal/hide will work in a real browser — a real-browser screenshot check is still recommended before considering this fully signed off)

## 6. Spec validation

- [x] 6.1 Run `openspec validate add-app-shell-navigation --strict` and fix any reported issues
