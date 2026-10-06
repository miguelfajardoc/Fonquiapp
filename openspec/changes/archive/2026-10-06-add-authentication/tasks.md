## 1. Generator and cleanup

- [x] 1.1 Run `bin/rails generate authentication` and `bundle install`, then run `bin/rails db:migrate` and `RAILS_ENV=test bin/rails db:prepare`. Check that `db/schema.rb` has `users` (with a unique `email_address`) and `sessions`, and that the Gemfile has `bcrypt` enabled.
- [x] 1.2 Delete `PasswordsController`, `PasswordsMailer`, `app/views/passwords/`, and `app/views/passwords_mailer/`. Remove `resources :passwords` and add `root "clients#index"` in `config/routes.rb`. Check that `bin/rails routes` lists `session`, `root`, and no `passwords` routes.

## 2. Login page

- [x] 2.1 Add `app/views/layouts/auth.html.erb` (the application `<head>`, centered body, flash, and `turbo-visit-control` reload meta), and set `layout "auth"` in `SessionsController`.
- [x] 2.2 Rewrite `sessions/new.html.erb` in Spanish: a card with the brand, "Iniciar sesión", the email and password fields, and an "Ingresar" button, in the app's styling, with no forgot-password link. Translate the controller's alert and rate-limit messages through `es.yml`.

## 3. Password change and header

- [x] 3.1 Add `resource :password_change, only: %i[edit update]` and `PasswordChangesController`, per design.md decision 4: it checks the current password, requires matching non-blank new values, and either redirects with a notice or re-renders with an error (422). Add `password_changes/edit.html.erb` inside the shell, plus its `es.yml` strings.
- [x] 3.2 Update `layouts/_header.html.erb`: the title on the left, and on the right the user's email, a "Cambiar contraseña" link, and a "Cerrar sesión" `button_to` (delete `session_path`). Add the `es.yml` strings.

## 4. Seeds

- [x] 4.1 Add a `User.find_or_create_by!` for `lacteosfonquilacpc@gmail.com` with password `123456` only on create to `db/seeds.rb`. Run `bin/rails db:seed` twice. Verify the user authenticates with `123456`, and that after changing the password in the console and re-seeding, the changed password still works. Restore `123456` afterwards.

## 5. Specs

- [x] 5.1 Add a `users` factory and `spec/support/authentication_helpers.rb` (`sign_in_as` and `sign_out`, an automatic sign-in before `type: :request` examples, opt-out with `:signed_out`). Verify the existing request specs pass unchanged.
- [x] 5.2 Add `spec/requests/authentication_spec.rb` (`:signed_out`):
  - A redirect to login, then a return to the requested page after signing in.
  - `/up` stays public.
  - Login succeeds with valid credentials and with different email case or surrounding spaces.
  - The same generic error for a wrong password and an unknown email.
  - The rate limit triggers.
  - Logout redirects, and pages require login again.
  - No `passwords` or sign-up routes.
  - The login page renders without the sidebar.
- [x] 5.3 Add specs for the password change (success keeps the user signed in and only the new password works afterwards; a wrong current password, a mismatch, and blank values are rejected) and for the header (email, "Cambiar contraseña", and "Cerrar sesión" shown). Add a `User` model spec (email normalization, uniqueness). Verify all pass.

## 6. Verification

- [x] 6.1 Run `bundle exec rspec` and `bin/rubocop` on the changed and new Ruby files. Confirm 0 failures and no new offenses.
- [x] 6.2 Headless Chromium against a temporary server:
  - A signed-out visit to `/clients` lands on the styled login page.
  - A wrong password shows the error.
  - The correct login returns to `/clients`, and the header shows the email.
  - "Cambiar contraseña" works. Restore `123456` afterwards.
  - "Cerrar sesión" goes back to login.
  - A filtered index still works while signed in.
- [x] 6.3 The user signs in with the seeded account in their browser and confirms the login page, header controls, and password change.
