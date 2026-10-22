## MODIFIED Requirements

### Requirement: Seeded staff account

The database seeds SHALL ensure a user with email address
"lacteosfonquilacpc@gmail.com" exists. The user's password SHALL be set only
when the user is created; running the seeds again SHALL NOT change the
password of an existing user.

Outside production, the user SHALL be created with the temporary password
"123456".

In production, the user SHALL be created with the password given in the
`ADMIN_PASSWORD` environment variable. When the user does not exist yet and
`ADMIN_PASSWORD` is missing or blank, production seeding SHALL fail with a
message naming `ADMIN_PASSWORD` and SHALL NOT create the user. Production
SHALL never create the user with the password "123456".

#### Scenario: Seeding creates the staff account once

- **GIVEN** no user "lacteosfonquilacpc@gmail.com" exists
- **AND** the environment is not production
- **WHEN** the seeds are run
- **THEN** that user exists and can sign in with "123456"

#### Scenario: Re-seeding keeps a changed password

- **GIVEN** the user "lacteosfonquilacpc@gmail.com" changed their password
- **WHEN** the seeds are run again
- **THEN** the user still signs in with the changed password

#### Scenario: Production seeding uses ADMIN_PASSWORD

- **GIVEN** no user "lacteosfonquilacpc@gmail.com" exists
- **AND** the environment is production
- **AND** `ADMIN_PASSWORD` is set to "s3cret-pass"
- **WHEN** the seeds are run
- **THEN** that user exists and can sign in with "s3cret-pass"
- **AND** the user cannot sign in with "123456"

#### Scenario: Production seeding without ADMIN_PASSWORD fails

- **GIVEN** no user "lacteosfonquilacpc@gmail.com" exists
- **AND** the environment is production
- **AND** `ADMIN_PASSWORD` is missing or blank
- **WHEN** the seeds are run
- **THEN** seeding fails with a message naming `ADMIN_PASSWORD`
- **AND** no user "lacteosfonquilacpc@gmail.com" exists

#### Scenario: Production re-seeding needs no ADMIN_PASSWORD

- **GIVEN** the user "lacteosfonquilacpc@gmail.com" already exists
- **AND** the environment is production
- **AND** `ADMIN_PASSWORD` is missing
- **WHEN** the seeds are run
- **THEN** seeding succeeds and the user's password is unchanged
