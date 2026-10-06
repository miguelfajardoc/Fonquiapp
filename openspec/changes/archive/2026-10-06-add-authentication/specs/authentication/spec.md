## Purpose

Authentication restricts the whole application to signed-in staff accounts:
it provides login and logout, keeps a user signed in across visits, lets a
signed-in user change their own password, and seeds the business's staff
account.

## ADDED Requirements

### Requirement: Access requires a signed-in user

Every page of the application SHALL require a signed-in user, except the
login page and the health check. A request from a visitor who is not signed
in SHALL be redirected to the login page. After signing in, the user SHALL be
returned to the page originally requested, or to the application's root page
when there was none.

#### Scenario: Signed-out visitor is sent to the login page

- **GIVEN** a visitor who is not signed in
- **WHEN** the client index is requested
- **THEN** the visitor is redirected to the login page
- **AND** no client data is shown

#### Scenario: Returning to the requested page after signing in

- **GIVEN** a signed-out visitor was redirected to the login page from the
  product index
- **WHEN** they sign in with valid credentials
- **THEN** they are taken to the product index

#### Scenario: Health check stays public

- **GIVEN** a visitor who is not signed in
- **WHEN** the health check is requested
- **THEN** it responds successfully without redirecting

### Requirement: Login with email and password

The login page SHALL ask for an email address and a password, in Spanish,
styled like the rest of the application and shown without the application
shell. Submitting the email and password of an existing user SHALL sign that
user in. Submitting an unknown email or a wrong password SHALL keep the
visitor on the login page with a single generic error that does not reveal
which of the two was wrong. Repeated login attempts from the same client
within a short time SHALL be rate-limited, showing an error asking to try
again later.

#### Scenario: Signing in with valid credentials

- **GIVEN** a user "lacteosfonquilacpc@gmail.com" with password "123456"
- **WHEN** the login form is submitted with that email and password
- **THEN** the user is signed in and taken to the application

#### Scenario: Email matching ignores case and surrounding spaces

- **GIVEN** a user "lacteosfonquilacpc@gmail.com"
- **WHEN** the login form is submitted with " LacteosFonquilacPC@gmail.com "
  and the correct password
- **THEN** the user is signed in

#### Scenario: Wrong password or unknown email

- **WHEN** the login form is submitted with a wrong password, or with an
  email that belongs to no user
- **THEN** no one is signed in
- **AND** the login page is shown again with the same generic error in both
  cases

#### Scenario: Too many attempts are rate-limited

- **GIVEN** many login attempts were just made from the same client
- **WHEN** another login attempt is made
- **THEN** it is rejected with an error asking to try again later

### Requirement: Staying signed in and signing out

A successful login SHALL keep the user signed in across browser restarts
until they sign out. Each login SHALL be recorded as a session of that user,
including the client's IP address and user agent. Signing out SHALL end the
current session and return the user to the login page; afterwards, pages
SHALL again require signing in.

#### Scenario: Signing out

- **GIVEN** a signed-in user
- **WHEN** the sign-out control is chosen
- **THEN** the user is taken to the login page
- **AND** requesting the client index redirects to the login page

### Requirement: No self sign-up and no email password reset

The system SHALL NOT offer a way to create an account from the web, and SHALL
NOT offer a password reset by email. Accounts SHALL be created only through
the database seeds or the console.

#### Scenario: No sign-up or reset routes

- **WHEN** a request is made to a sign-up page or to a password-reset page
- **THEN** the system reports no matching route

### Requirement: Changing one's own password

A signed-in user SHALL be able to change their own password from a page
reachable from the header. The page SHALL ask for the current password, the
new password, and the new password again. The change SHALL be saved only
when the current password is correct and the two new values match and are
not blank; otherwise the page SHALL be shown again with an error and the
password SHALL NOT change. After a successful change, the user SHALL remain
signed in and see a confirmation.

#### Scenario: Changing the password with valid input

- **GIVEN** a signed-in user whose password is "123456"
- **WHEN** the password change form is submitted with current password
  "123456" and new password "nuevaClave9" twice
- **THEN** the password is changed and a confirmation is shown
- **AND** the user can later sign in with "nuevaClave9" but not with "123456"

#### Scenario: Wrong current password

- **WHEN** the password change form is submitted with an incorrect current
  password
- **THEN** the password does not change
- **AND** the page is shown again with an error

#### Scenario: New passwords do not match

- **WHEN** the password change form is submitted with two different new
  passwords
- **THEN** the password does not change
- **AND** the page is shown again with an error

### Requirement: Seeded staff account

The database seeds SHALL ensure a user with email address
"lacteosfonquilacpc@gmail.com" exists, created with the temporary password
"123456" only when that user does not exist yet. Running the seeds again
SHALL NOT change the password of an existing user.

#### Scenario: Seeding creates the staff account once

- **GIVEN** no user "lacteosfonquilacpc@gmail.com" exists
- **WHEN** the seeds are run
- **THEN** that user exists and can sign in with "123456"

#### Scenario: Re-seeding keeps a changed password

- **GIVEN** the user "lacteosfonquilacpc@gmail.com" changed their password
- **WHEN** the seeds are run again
- **THEN** the user still signs in with the changed password
