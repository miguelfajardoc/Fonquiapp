# local-production-environment Specification

## Purpose

Lets the real-data instance of the app run on the developer's own machine,
isolated from development seed data, with repeatable commands to set it up,
update it after code changes, start it, and back up its data.

## Requirements

### Requirement: Separate databases per environment

The real-data instance SHALL run in the production environment and SHALL
store its data only in the production databases (`fonquiapp_production` and
its `_cache`, `_queue` and `_cable` companions). Development SHALL store its
data only in `fonquiapp_development`. No command defined by this capability
SHALL read from or write to one environment's database while acting on the
other.

#### Scenario: Development data does not appear in the real app

- **GIVEN** the development database contains seeded sample clients
- **WHEN** the real app is started and its client list is viewed
- **THEN** none of the development sample clients are listed

#### Scenario: Resetting development leaves real data intact

- **GIVEN** the production database contains real clients
- **WHEN** the development database is reset and reseeded
- **THEN** the production database still contains exactly the same real clients

### Requirement: Sample data only in development

Seeding SHALL load sample data (fake zones, products, clients, routes, route
stops, default product quantities and pending products) only in the
development environment. Seeding outside development SHALL NOT create sample
records and SHALL NOT delete any existing records.

#### Scenario: Development seeding loads sample data

- **WHEN** the seeds are run in development
- **THEN** sample zones, products, clients, routes and route stops exist

#### Scenario: Production seeding preserves real data

- **GIVEN** the production database contains real route stops, default
  product quantities and pending products
- **WHEN** the seeds are run in production
- **THEN** all of those records still exist unchanged
- **AND** no sample zones, products or clients were created

### Requirement: First-time setup command

The system SHALL provide a setup command that creates and loads the schema of
every production database that does not exist yet, then runs the production
seeds. It SHALL be safe to run again: on a machine that is already set up, it
SHALL NOT drop, truncate or alter existing real data.

#### Scenario: Setup on a fresh machine

- **GIVEN** no production databases exist
- **AND** `ADMIN_PASSWORD` is set
- **WHEN** the setup command is run
- **THEN** the four production databases exist with their schemas loaded
- **AND** the staff account can sign in to the real app with `ADMIN_PASSWORD`

#### Scenario: Setup run again keeps data

- **GIVEN** the production database already contains real clients
- **WHEN** the setup command is run again
- **THEN** the real clients are unchanged

### Requirement: Update command

The system SHALL provide an update command for applying new code to the real
app. It SHALL first take a backup of the production database, then apply
pending migrations to every production database, then rebuild the production
assets. If any step fails, it SHALL stop, report the failing step and exit
with a non-zero status without running later steps.

#### Scenario: Update applies pending migrations

- **GIVEN** the code contains a migration not yet applied to production
- **WHEN** the update command is run
- **THEN** a new backup file exists
- **AND** the migration is applied to the production database
- **AND** the production assets reflect the current code

#### Scenario: Backup failure stops the update

- **GIVEN** the backup step fails
- **WHEN** the update command is run
- **THEN** no migration is applied
- **AND** the command exits with a non-zero status naming the backup step

### Requirement: Start command on port 3001

The system SHALL provide a start command that serves the real app in the
production environment on port 3001 by default, over plain HTTP on the local
machine. The command SHALL refuse to start, with an explanatory message, when
the production assets have not been built or when the production database
has pending migrations.

#### Scenario: Real app is reachable on 3001

- **GIVEN** setup has been completed
- **WHEN** the start command is run
- **THEN** the login page is served at http://localhost:3001

#### Scenario: Missing assets block start

- **GIVEN** the production assets have never been built
- **WHEN** the start command is run
- **THEN** the server does not start
- **AND** the message tells the user to run the update command

#### Scenario: Pending migrations block start

- **GIVEN** the code contains a migration not yet applied to production
- **WHEN** the start command is run
- **THEN** the server does not start
- **AND** the message tells the user to run the update command

### Requirement: Production assets do not affect development

Building the production assets SHALL NOT change which stylesheets and
scripts development serves. After a production asset build, development
SHALL still serve assets compiled live from the current source.

#### Scenario: Style change visible in development after a production build

- **GIVEN** the production assets have been built
- **WHEN** a stylesheet source is changed and a page is loaded in development
- **THEN** the page uses the changed style

### Requirement: Manual backup command

The system SHALL provide a backup command that writes a complete dump of
`fonquiapp_production` to a timestamped file in a backup directory outside
the WSL filesystem. The backup directory SHALL be configurable. The command
SHALL exit with a non-zero status and an explanatory message when the dump
tool is unavailable, the database cannot be reached, or the directory cannot
be written. It SHALL never delete or overwrite an existing backup file.

#### Scenario: Backup writes a timestamped dump

- **GIVEN** the production database is reachable
- **WHEN** the backup command is run
- **THEN** a new file whose name contains the current date and time exists in
  the backup directory
- **AND** restoring that file into an empty database reproduces the
  production data

#### Scenario: Missing dump tool is reported

- **GIVEN** the PostgreSQL dump tool is not installed
- **WHEN** the backup command is run
- **THEN** the command exits with a non-zero status
- **AND** the message says how to install the PostgreSQL client
