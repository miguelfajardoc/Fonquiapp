# Fonquiapp

Rails app for Fonquilac's zones, clients, routes, products and orders.

## Two environments on one machine

Development and real use run from the same checkout. Each has its own PostgreSQL databases:

| | Development | Real use (production) |
|---|---|---|
| Databases | `fonquiapp_development` | `fonquiapp_production` (+ `_cache`, `_queue`, `_cable`) |
| Data | Sample data from the seeds | Real data, never seeded with samples |
| Start | `bin/dev` | `bin/local-prod start` |
| URL | http://localhost:3000 | http://localhost:3001 |

Run only one of them at a time.

## Development

```bash
bin/setup                 # install gems, prepare the database, start bin/dev
bin/rails db:reset        # rebuild the development database with fresh sample data
bundle exec rspec         # tests
```

`db/seeds.rb` only creates the staff user (password `123456` outside production).
The sample data lives in `db/seeds/development.rb` and is loaded only in development.

## Real use (`bin/local-prod`)

### Prerequisites

- PostgreSQL client tools, at the same major version as the server or newer: `sudo apt install postgresql-client`
- A `.env.local-prod` file (git-ignored) in the project root that sets where backups go. Use a folder outside
  WSL, ideally one synced to the cloud:

  ```
  BACKUP_DIR=/mnt/c/Users/<you>/OneDrive/fonquiapp-backups
  ```

### First time

```bash
ADMIN_PASSWORD='choose-a-password' bin/local-prod setup
bin/local-prod start
```

`setup` creates the production databases, the staff user `lacteosfonquilacpc@gmail.com` with `ADMIN_PASSWORD`,
and the production assets. The password is only used when the user is created. Change it later from
"Cambiar contraseña" in the app.

### Every day

```bash
bin/local-prod start      # Ctrl+C to stop
```

### After new features (pull or commit)

```bash
bin/local-prod update     # backup -> migrate production -> rebuild assets
bin/local-prod start
```

`start` refuses to run while migrations are pending or assets are missing, and tells you to run `update`.
Commit your work before `update`: whatever is in the folder becomes the real app.

### Backups

```bash
bin/local-prod backup     # writes BACKUP_DIR/fonquiapp_production-YYYYMMDD-HHMMSS.dump
```

To restore a backup (stop the app first):

```bash
pg_restore --clean --if-exists -h 127.0.0.1 -U postgres -d fonquiapp_production BACKUP_DIR/<file>.dump
```
