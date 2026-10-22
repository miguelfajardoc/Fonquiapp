## Why

The app's first real use runs on the developer's own computer, with one user. Real data and development seed data have to live side by side on that machine without mixing. Today `db/seeds.rb` mixes bootstrap and sample data: it creates a staff user with the password "123456", inserts fake zones, products and clients, and calls `delete_all` on route stops, default quantities and pending products. If it ran against real data, it would plant fake records and wipe real ones. There is also no repeatable way to set up, update or back up a real-data instance.

## What Changes

- Run the real-data instance in `RAILS_ENV=production` on the same machine and the same checkout. It uses its own PostgreSQL databases (`fonquiapp_production` plus `_cache`, `_queue` and `_cable`) and serves on port 3001. Development keeps `fonquiapp_development` with seed data on port 3000. Only one of them runs at a time.
- Split the seeds: `db/seeds.rb` keeps only bootstrap data that is safe in every environment. The sample data (Faker, `delete_all`, random clients and routes) moves to a development-only file that never runs in production.
- **BREAKING (production seeding)**: in production, the seeded staff account takes its password from the `ADMIN_PASSWORD` environment variable, and seeding refuses to run when that variable is missing and the user does not exist yet. Development keeps the "123456" default.
- Add a `bin/local-prod` command with these subcommands:
  - `setup`: first-time creation of the production databases and the staff user.
  - `update`: back up, migrate the production databases and precompile assets after pulling new code.
  - `start`: serve the real app on port 3001.
  - `backup`: `pg_dump` of `fonquiapp_production` into a folder outside WSL.
- Precompiled production assets must not shadow live development assets.
- Out of scope: automatic or scheduled backups, restore tooling beyond a documented command, running both instances at once, and remote or multi-user deployment.

## Capabilities

### New Capabilities
- `local-production-environment`: how the real-data instance is isolated from development on one machine, and the setup, update, start and backup operations for it.

### Modified Capabilities
- `authentication`: the "Seeded staff account" requirement changes so that production takes the initial password from `ADMIN_PASSWORD` instead of the hardcoded "123456".

## Impact

- **Code**: `db/seeds.rb`, new `db/seeds/development.rb`, new `bin/local-prod`, `config/environments/production.rb` (asset output path and URL prefix), `.gitignore` (local env file and backups, if needed).
- **Systems**: needs a PostgreSQL client (`pg_dump`) inside WSL, because the server runs outside the distro and `pg_dump` is not currently installed. Backups are written under `/mnt/c/...` (Windows side).
- **Workflow**: after each feature, besides migrating development, the developer runs `bin/local-prod update` before using the real app.
- **Tests**: new specs cover the seed split and the production password guard.
