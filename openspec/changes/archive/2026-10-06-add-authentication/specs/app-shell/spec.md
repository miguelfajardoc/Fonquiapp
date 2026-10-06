## MODIFIED Requirements

### Requirement: Persistent sidebar and header on every page

The system SHALL render every page shown to a signed-in user inside a shared
shell consisting of a sidebar and a header. The sidebar SHALL display the
brand label "Fonquilac" above its navigation entries. The login page SHALL be
rendered without the shell.

#### Scenario: Shell wraps an existing page

- **GIVEN** a user is signed in
- **WHEN** any existing page (for example the zone index or the client
  index) is rendered
- **THEN** the sidebar and header are present around that page's content
- **AND** the sidebar shows the brand label "Fonquilac"

#### Scenario: Login page has no shell

- **WHEN** the login page is rendered
- **THEN** no sidebar or header is displayed

## REMOVED Requirements

### Requirement: No user identity displayed

**Reason**: Users and sessions now exist (`authentication` capability), and
staff need to see which account is signed in and how to sign out.
**Migration**: Replaced by "Signed-in account controls in the header" below.

## ADDED Requirements

### Requirement: Signed-in account controls in the header

On every page inside the shell, the header SHALL show, aligned to its right
side, the signed-in user's email address, a control to open the password
change page, and a control to sign out. No avatar SHALL be displayed.

#### Scenario: Header shows the signed-in account

- **GIVEN** the user "lacteosfonquilacpc@gmail.com" is signed in
- **WHEN** any page inside the shell is rendered
- **THEN** the header shows "lacteosfonquilacpc@gmail.com"
- **AND** it shows a "Cambiar contraseña" control and a "Cerrar sesión"
  control
