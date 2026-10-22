## 1. Split the seeds

- [x] 1.1 Move all sample-data code (Faker helpers, zones, products, clients, routes, route stops, default product quantities, pending products) from `db/seeds.rb` into a new `db/seeds/development.rb`, unchanged. Verify with `bin/rails db:reset` in development: it produces the same kinds of sample records as before.
- [x] 1.2 Leave only the staff user in `db/seeds.rb` and add `load Rails.root.join("db/seeds/development.rb") if Rails.env.development?`. Update the header comment to explain the split. Verify by grepping: `db/seeds.rb` no longer references `Faker` or `delete_all`.
- [x] 1.3 Make the staff password `ENV["ADMIN_PASSWORD"].presence` in production, aborting with a message that names `ADMIN_PASSWORD` when it is missing, and keep "123456" elsewhere. Set the password only inside the create block. Verify with the specs in 1.4.
- [x] 1.4 Add `spec/db/seeds_spec.rb` that loads `db/seeds.rb` with `Rails.env` stubbed. Cover each scenario of the authentication "Seeded staff account" delta, and check that non-development seeding leaves existing route stops, default quantities and pending products untouched and creates no zones, products or clients. Verify with `bundle exec rspec spec/db/seeds_spec.rb`.

## 2. Separate production assets

- [x] 2.1 Set `config.assets.prefix = "/prod-assets"` in `config/environments/production.rb` and add `/public/prod-assets` to `.gitignore`. Verify: `RAILS_ENV=production bin/rails assets:precompile` writes to `public/prod-assets/.manifest.json` and leaves `public/assets/` absent.
- [x] 2.2 After that production build, check that development still compiles live. Start `bin/dev`, change a Tailwind class in a view, and see the change at http://localhost:3000 (use headless Chromium).

## 3. `bin/local-prod` script

- [x] 3.1 Create executable `bin/local-prod` in Ruby, in the style of `bin/setup`. It forces `RAILS_ENV=production` for child processes, loads `KEY=value` lines from `.env.local-prod` without overriding variables already set, dispatches `setup|update|start|backup`, and prints usage and exits 1 for anything else. Verify: `bin/local-prod foo` prints usage and exits 1.
- [x] 3.2 Implement `backup`: check `pg_dump` with `command -v` and print install advice if it is missing, require `BACKUP_DIR` (create it if absent), and run `pg_dump -Fc` with the connection settings from `DATABASE_*` env vars and their defaults (password via `PGPASSWORD` for the child process only) to `fonquiapp_production-YYYYMMDD-HHMMSS.dump`, refusing to overwrite an existing file. Verify: running it twice creates two files, and `pg_restore --list` reads both.
- [x] 3.3 Implement `setup`: `db:prepare`, then `db:seed`, then `assets:precompile`. Verify on a machine without the production databases: `ADMIN_PASSWORD=... bin/local-prod setup` creates all four databases (`psql -l` or `bin/rails dbconsole`), and running it again without `ADMIN_PASSWORD` succeeds and leaves the data unchanged.
- [x] 3.4 Implement `update`: print a warning when `git status --porcelain` is not empty, then run `backup`, then `db:migrate`, then `assets:precompile`, stopping at the first failure with the step name and a non-zero exit. Verify: with `BACKUP_DIR` unset, `update` exits non-zero and does not migrate.
- [x] 3.5 Implement `start`: refuse with "run bin/local-prod update" when `public/prod-assets/.manifest.json` is missing or `db:migrate:status` shows any `down` migration. Otherwise `exec` `bin/rails server -p ${PORT:-3001}` with `PIDFILE=tmp/pids/production.pid`. Verify: after removing `public/prod-assets`, start refuses; after `update`, it serves the login page at http://localhost:3001.

## 4. Environment setup and documentation

- [x] 4.1 Find the PostgreSQL server's major version (`SELECT version();`) and install the matching `postgresql-client` in WSL. Verify that `pg_dump --version` matches.
- [x] 4.2 Document the local production workflow in `README.md`: prerequisites, `.env.local-prod` with `BACKUP_DIR`, first-time `setup` with `ADMIN_PASSWORD`, the daily `start`, `update` after pulling or committing new features, manual `backup`, and a one-line restore (`pg_restore --clean -d fonquiapp_production <file>`). Verify by following the README from a fresh production database.

## 5. End-to-end verification

- [x] 5.1 Run the full flow from a fresh state: `setup`, `start`, sign in at :3001 with `ADMIN_PASSWORD`, create a real client, stop, then `bin/rails db:reset` in development and `bin/dev`. Check that the real client is absent at :3000 and the sample clients are absent at :3001. Verify with headless Chromium screenshots of both client lists.
- [x] 5.2 Run `bundle exec rspec` and `bin/rubocop`, and verify both pass.
