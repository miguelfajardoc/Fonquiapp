## Context

See proposal.md (Why). Current state:

- Rails 8.1.3. `bcrypt` is commented out in the Gemfile. There is no `User`
  model, no root route, and no `ApplicationCable::Connection`.
- `bin/rails generate authentication --pretend` would create:
  - Models: `User`, `Session`, `Current`.
  - Controllers: the `Authentication` concern, `SessionsController`, and
    `PasswordsController` with `PasswordsMailer` and its views.
  - Views: `sessions/new`.
  - `ApplicationCable::Connection`.
  - The `users` and `sessions` migrations.
  - It also adds `include Authentication` to `ApplicationController`, the
    routes `resource :session` and `resources :passwords`, and enables
    `bcrypt` in the Gemfile.

  It cannot generate RSpec files, so specs are written by hand.
- Layout: `layouts/application` renders the sidebar and `layouts/_header`
  (title only) around `main`. Styling uses Tailwind tokens (`bg-bg`,
  `bg-surface`, `border-border`, `text-text`, `bg-accent`,
  `text-accent-contrast`) and the `filter_control_class` and
  `create_button_class` helpers.
- About 260 request specs hit controllers directly and would all redirect
  once authentication is required.
- Production mail is not configured (`example.com`, no SMTP).

## Goals / Non-Goals

**Goals:**
- Restrict every page to signed-in users with the stock Rails 8 mechanism, so
  future Rails upgrades and docs apply as-is.
- Provide a self-service password change for the temporary password, without
  needing email.

**Non-Goals:**
- No sign-up, roles, or multiple-user management UI. The single staff
  account comes from seeds, and more can be added from the console.
- No password reset by email (user decision). Revisit once SMTP exists.
- No "remember me" checkbox. The generator's session cookie is already
  permanent until sign-out.

## Decisions

### 1. Run the generator, then remove the email reset pieces

Run `bin/rails generate authentication`, then delete `PasswordsController`,
`PasswordsMailer`, `views/passwords/*`, and `views/passwords_mailer/*`.
Remove the `resources :passwords` route and the "forgot password" link from
`sessions/new`. Keep the rest of the generated code as-is (rate limit
`only: :create`, `start_new_session_for`, signed permanent `session_id`
cookie, `normalizes :email_address`, and `allow_unauthenticated_access`).

*Alternative*: hand-write authentication or use Devise. That means more code
to own, or a large dependency, for one login.

### 2. Root route and redirect target

Add `root "clients#index"`. The generator's `after_authentication_url`
returns the stored return-to URL or `root_url`. Clients is the main working
list, and this can be changed later without affecting anything else.

### 3. Login page layout and style

Add `layouts/auth.html.erb`: the same `<head>` as the application layout
(stylesheets, importmap, CSRF, and title), plus a body
`min-h-screen flex items-center justify-center bg-bg` holding the flash and
the yield. `SessionsController` uses `layout "auth"`.

Rewrite `sessions/new.html.erb` in Spanish as a `bg-surface` bordered card
(`max-w-sm`):
- The brand "Fonquilac" and the heading "Iniciar sesión".
- An email field and a password field (`filter_control_class`, full width).
- The submit button ("Ingresar", accent style).

The error flash shows "Correo o contraseña incorrectos." for bad
credentials, and the rate-limit message "Demasiados intentos. Intenta de
nuevo más tarde.", both from `es.yml`.

The login form is submitted without Turbo (`data-turbo="false"`). The auth
layout's `turbo-visit-control: reload` meta makes Turbo reload any page it
fetches with that layout. On a Turbo form submission, that reload would
consume the flash on the first fetch and show the reloaded page without the
error. This was found during headless-browser verification.

### 4. Password change for the signed-in user

Add `resource :password_change, only: %i[edit update]` (`GET/PATCH
/password_change/edit`, `/password_change`) and `PasswordChangesController`:
- `update` checks `Current.user.authenticate(params[:current_password])`.
  On success it calls `update(password:, password_confirmation:)`, with
  `has_secure_password` validating presence and confirmation. Blank new
  values are rejected explicitly.
- Success: redirect to `edit_password_change_path` with notice "Contraseña
  actualizada." The current session stays signed in.
- Failure: re-render `edit` (422) with an error ("La contraseña actual no es
  correcta." or the confirmation/blank validation message).

The view is a page inside the normal shell, with the title "Cambiar
contraseña", in the same form style as the other create/edit pages.

### 5. Header account controls

`layouts/_header.html.erb` becomes `flex justify-between`: the title on the
left, and on the right, when `authenticated?`, `Current.user.email_address`
(muted), a "Cambiar contraseña" link, and a "Cerrar sesión"
`button_to session_path, method: :delete` (bordered button). The header
only renders inside the application layout, so the auth layout never shows
it.

### 6. Seeds

```ruby
User.find_or_create_by!(email_address: "lacteosfonquilacpc@gmail.com") do |user|
  user.password = "123456"
end
```

The block runs only on create, so re-seeding never resets a changed
password. Place it at the top of `db/seeds.rb` (idempotent like the rest).

### 7. Specs keep working through a default sign-in

Add `spec/support/authentication_helpers.rb`:
- `sign_in_as(user)` posts to `session_path`.
- `sign_out` deletes `session_path`.
- An RSpec hook signs in a fresh user before every `type: :request` example,
  unless it is tagged `:signed_out`.

New authentication specs use `:signed_out` to exercise redirects and login.
Add a `users` factory. The headless-browser checks also sign in first.

## Risks / Trade-offs

- [`123456` is weak and committed in the repository's seeds, and seeds may run
  in production.] → It is created only if missing, and the user is told to
  change it right after first login through "Cambiar contraseña". A later
  change can force a change on first login if needed.
- [Every request now needs a session lookup.] → One indexed query per request
  (`sessions.id`), which is negligible at this scale.
- [Turbo frame requests from a signed-out (expired) session get a redirect to
  the login page, which a frame cannot render ("Content missing").] → Sessions
  only end on explicit sign-out, so this is rare. If it shows up, add
  `data-turbo-visit-control="reload"` to the login page so Turbo does a full
  visit (cheap to add now). Include it in the auth layout.
- [The generator also adds `ApplicationCable::Connection` that authenticates
  by cookie.] → No channels are used yet. It is harmless and correct for
  future broadcasts.

## Migration Plan

1. `bundle install` (bcrypt), then run the migrations (`users`, `sessions`)
   and `bin/rails db:seed` to create the staff account.
2. Deploy. Run `db:seed` once in production (or create the user from the
   console), then sign in and change the password immediately.
3. Rollback: revert the code and roll back the two migrations. No other data
   is affected.
