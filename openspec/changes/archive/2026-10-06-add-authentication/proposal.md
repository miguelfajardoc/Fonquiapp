## Why

Every screen of the app (clients, routes, products, orders) is open to anyone
who can reach the server, with no login at all. Before the app is used in
production, access must be restricted to the business's own staff account.

## What Changes

- Add login and logout, using Rails 8's built-in authentication generator
  (`bin/rails generate authentication`). It adds `User` (email address and
  bcrypt password), `Session` (one record per login, tracked by a signed
  cookie), `Current`, and an `Authentication` concern that requires a
  signed-in user on every page by default.
- **Every existing page now requires login.** A signed-out visitor is sent to
  the login page and returned to the page they asked for after signing in.
  The health check (`/up`) stays public.
- A login page in Spanish, styled like the rest of the app (same color tokens,
  inputs, and buttons). It is a centered card without the sidebar or header.
  Wrong credentials show an error without saying which part was wrong.
  Repeated attempts are rate-limited (the generator's default).
- **No public sign-up and no password reset by email** (user decision). The
  generator's `PasswordsController`, mailer, and reset views are removed.
  Instead, a signed-in user gets a **"Cambiar contraseña"** page that asks for
  the current password and the new one, entered twice.
- The header shows the signed-in user's email, a "Cambiar contraseña" link,
  and a "Cerrar sesión" button on its right side (user decision).
  **BREAKING (spec)**: this replaces the app-shell rule that no user identity
  is displayed.
- Seeds create the staff user `lacteosfonquilacpc@gmail.com` with the
  temporary password `123456`, only if that user does not exist yet. Re-running
  the seeds never resets a password that was already changed.
- Add `bcrypt`, uncommented in the Gemfile.

## Capabilities

### New Capabilities

- `authentication`: login, logout, access restriction, password change, and
  the seeded staff account.

### Modified Capabilities

- `app-shell`: the shell displays the signed-in user's email and account
  controls in the header, instead of showing no identity.

## Impact

- **Dependencies**: `bcrypt` gem.
- **Database**: new `users` table (`email_address` unique, `password_digest`)
  and new `sessions` table (`user_id`, `ip_address`, `user_agent`).
- **New code**:
  - From the generator: `User`, `Session`, `Current`, the
    `Authentication` concern, `SessionsController`, the session view, and
    `ApplicationCable::Connection`.
  - A new `PasswordChangesController` with its view and route.
  - A minimal layout for the login page.
- **Changed code**: `ApplicationController` (includes `Authentication`), the
  header partial, `config/routes.rb`, `es.yml`, and `db/seeds.rb`.
- **Tests**: a request-spec helper that signs in by default, so the existing
  ~260 request specs keep passing. New specs for login, logout, the
  redirect, the rate limit, the password change, and the header controls.
- **Security note**: `123456` is a weak, publicly visible password in the
  repository's seeds. It must be changed on first login, especially in
  production.
