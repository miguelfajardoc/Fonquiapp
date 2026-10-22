## Context

See proposal.md for the motivation. Relevant current state:

- `config/database.yml` already gives each environment its own databases on the same PostgreSQL server (127.0.0.1:5432). Production has four: primary, `_cache`, `_queue` and `_cable`. No changes are needed there.
- `config/environments/production.rb` works over plain HTTP on localhost because `force_ssl` and `assume_ssl` are commented out. `config/master.key` exists, so credentials (`secret_key_base`, Google Maps key) decrypt in production. Logs go to stdout.
- `db/seeds.rb` mixes the staff user with Faker sample data and `delete_all` calls. `faker` is in the `:development, :test` group, so production seeding crashes when it reaches Faker, but by then it has already created the "123456" user and fake zones and products.
- PostgreSQL runs outside this WSL distro. `pg_dump` and `psql` are not installed inside WSL. The Windows user folder is reachable at `/mnt/c/Users/<name>/`.
- Propshaft picks its resolver from whether `public/assets/.manifest.json` exists (see `Propshaft::Assembly#resolver`). A production `assets:precompile` into the default `public/assets` would make **development** serve the stale precompiled files.
- Puma reads `PORT` (default 3000) and `PIDFILE` from the environment.
- There are no Active Job jobs yet, so production needs no Solid Queue worker.

## Goals / Non-Goals

**Goals:**
- One command entry point that makes it hard to point a production operation at the wrong database or forget a step.
- Seeds that cannot damage real data, whatever environment they run in.

**Non-Goals:**
- Running production as a background service or Windows startup task. The developer starts it by hand.
- Kamal or Docker deployment. The existing Kamal files are left alone.
- A restore command. Restoring is documented as a one-line `pg_restore`.

## Decisions

### 1. Use the real `production` environment, not a custom one

`RAILS_ENV=production` already has the right database names, caching, eager loading and Solid adapters. A custom `local` environment would duplicate all of that and drift from it.

### 2. Split the seeds by environment

`db/seeds.rb` keeps only the staff user, then ends with:

```ruby
load Rails.root.join("db/seeds/development.rb") if Rails.env.development?
```

`db/seeds/development.rb` takes over all existing sample-data code unchanged: Faker helpers, zones, products, clients, routes, and the `delete_all` regeneration blocks.

- The guard is an allow-list (`development?`) rather than `unless production?`. Any future environment then defaults to safe.
- Test runs don't use the seeds (factories cover that), so excluding `test` costs nothing.
- Alternative considered: separate rake tasks such as `db:seed:sample`. Rejected because it changes the familiar `bin/rails db:seed` / `db:reset` flow for development.

### 3. Staff password: environment-dependent default

```ruby
User.find_or_create_by!(email_address: STAFF_EMAIL) do |user|
  user.password = Rails.env.production? ? ENV.fetch("ADMIN_PASSWORD") { abort "..." } : "123456"
end
```

- The block runs only when the user is created. Re-seeding with no `ADMIN_PASSWORD` is therefore fine once the user exists, as the spec requires.
- Blank values count as missing, so the implementation uses `ENV["ADMIN_PASSWORD"].presence`. It raises or aborts with a message naming the variable.
- The password is passed only for the setup run (`ADMIN_PASSWORD=... bin/local-prod setup`). It is never written to a file. The user can change it later in the app.

### 4. A single `bin/local-prod` script with subcommands

The script is a Ruby script in the same style as `bin/setup` (`system!` helper, `FileUtils.chdir APP_ROOT`). It sets `RAILS_ENV=production` for every child process, so nothing relies on the caller's shell.

| Subcommand | Steps |
|---|---|
| `setup` | `bin/rails db:prepare` (creates and loads all four databases and seeds only new ones), then `bin/rails db:seed`, then `assets:precompile` |
| `update` | `backup`, then `bin/rails db:migrate` (all four databases), then `assets:precompile` |
| `start` | checks that the prod manifest exists, then `exec bin/rails server -p ${PORT:-3001}` with `PIDFILE=tmp/pids/production.pid` |
| `backup` | `pg_dump -Fc` to `$BACKUP_DIR/fonquiapp_production-YYYYMMDD-HHMMSS.dump` |

- `db:prepare` on a fresh database already runs the seeds. The explicit `db:seed` is idempotent and covers a database that exists but has no staff user.
- Connection settings (`DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME`, `DATABASE_PASSWORD`) come from the same env vars and defaults as `database.yml`. `pg_dump` gets the password through `PGPASSWORD` for the child process only.
- The custom format (`-Fc`) is compressed and restorable with `pg_restore`. The file name has a timestamp down to the second, and the script refuses to overwrite an existing file.
- Each step's failure raises, so later steps never run. `system!` with `exception: true` already does this.
- Alternatives considered: several `bin/prod-*` scripts (more files, more duplicated env setup), or rake tasks (they would load the app in whatever environment the caller had set, which is exactly the mistake we want to avoid).

### 5. Backup directory configuration

`BACKUP_DIR` comes from the environment. If it isn't set, the script reads `.env.local-prod` (already covered by `/.env*` in `.gitignore`), a plain `KEY=value` file parsed by the script, so no dotenv gem is needed. If it's still unset, the script fails and tells the user to set it, e.g. `BACKUP_DIR=/mnt/c/Users/<name>/OneDrive/fonquiapp-backups`. There is no guessed default, so backups never land somewhere the user doesn't know about. The script creates the directory if it is missing.

### 6. Separate output path for production assets

In `production.rb`, set `config.assets.prefix = "/prod-assets"`. The output path is derived from the prefix (`public/prod-assets`), so development's resolver never sees a manifest in `public/assets` and stays dynamic. Production serves the files from `public/` through Rails' public file server, which is enabled by default. Add `/public/prod-assets` to `.gitignore`.

- Alternative considered: run `assets:clobber` before every dev start. Rejected because it is easy to forget, and it would also delete production's assets.
- Tailwind writes its build to the shared `app/assets/builds/tailwind.css`. That is fine because `bin/dev` rebuilds it in watch mode, and the production precompile rebuilds it before copying.

## Risks / Trade-offs

- [Forgetting `bin/local-prod update` after pulling code] → The real app hits pending migrations or stale assets. Mitigation: `start` also refuses to run if `ActiveRecord::Migration` reports pending migrations for production, by running `bin/rails db:migrate:status` and looking for `down`. This adds a cheap check to `start`, which is covered by a task.
- [Single-machine data loss (disk, WSL distro reset)] → Backups go to the Windows side, ideally a OneDrive-synced folder. They are still manual, which is an accepted trade-off. Scheduling is out of scope.
- [Migration that destroys data] → `update` always backs up first, so the user can roll back with `pg_restore`.
- [`pg_dump` version older than the server] → `pg_dump` refuses to run. Mitigation: install a client with the same major version as the server, or newer. The error message is printed as-is.
- [Same checkout for both environments] → Uncommitted work-in-progress becomes the real app at the next `update`/`start`. Accepted, because only one app runs at a time. The README notes that `update` should run on a clean, committed tree; the script prints a warning when `git status --porcelain` is not empty.
- [Production log volume] → Logs go to stdout only, so nothing grows on disk.

## Migration Plan

1. Install a PostgreSQL client in WSL (`sudo apt install postgresql-client-<server major>`).
2. Create `.env.local-prod` with `BACKUP_DIR=...`.
3. `ADMIN_PASSWORD='...' bin/local-prod setup`
4. `bin/local-prod start`, then open http://localhost:3001 and sign in.

Rollback: delete the production databases (`RAILS_ENV=production bin/rails db:drop` with `DISABLE_DATABASE_ENVIRONMENT_CHECK=1`) and `public/prod-assets`. Development is not affected either way.

## Open Questions

- The exact major version of the PostgreSQL server, which decides the client package name. Check with `SELECT version();` during implementation.
