## 1. Zone model and migration

- [x] 1.1 Generate the `zones` migration — `name:string` `NOT NULL`, a unique index on `name`, timestamps. Verify `bin/rails db:migrate` creates the table and `db/schema.rb` shows `t.string "name", null: false` plus a unique index on `name`.
- [x] 1.2 Create `app/models/zone.rb` with `has_many :clients, dependent: :restrict_with_error` and `validates :name, presence: true, uniqueness: true`. Verify in `bin/rails runner` that `Zone.create!(name: "Norte")` succeeds and a second `Zone.create(name: "Norte")` returns `valid? == false` with an error on `:name`.

## 2. Client model, migration, and association

- [x] 2.1 Generate the `clients` migration — `name:string` `NOT NULL`, nullable `address:string`, `url:string`, `phone:string`, `add_reference :clients, :zone, null: false, foreign_key: true`, timestamps. Verify `bin/rails db:migrate` succeeds and `db/schema.rb` shows the `zone_id` index and the `foreign_key "zones"` on `clients`.
- [x] 2.2 Create `app/models/client.rb` with `belongs_to :zone` and `validates :name, presence: true`. Verify a `Client` built with a persisted zone and a name is `valid?`, while `Client.new.valid?` is `false` with errors on both `:name` and `:zone`.
- [x] 2.3 Verify database-level referential integrity: in `bin/rails runner`, inserting a client row with a `zone_id` that matches no zone raises `ActiveRecord::InvalidForeignKey`.

## 3. Factories and model specs

- [x] 3.1 Add `spec/factories/zones.rb` (sequenced unique `name`) and `spec/factories/clients.rb` (`association :zone`; `address`, `url`, `phone` populated with Faker). Verify `bundle exec rspec` with a `FactoryBot.lint` spec (or `bin/rails runner "FactoryBot.lint"`) reports no invalid factories.
- [x] 3.2 Add `spec/models/zone_spec.rb` covering every Zone-record and relationship scenario from the `client-directory` spec: valid with a name; invalid when `name` is blank; invalid on duplicate `name`; deleting a zone that has clients is blocked and leaves both intact; a zone with no clients is deletable; `zone.clients` returns exactly the clients that reference it. Verify `bundle exec rspec spec/models/zone_spec.rb` passes.
- [x] 3.3 Add `spec/models/client_spec.rb` covering every Client-record scenario from the spec: valid with `name` + zone; invalid when `name` is blank; invalid with no zone; valid when `address`/`url`/`phone` are omitted (and those fields read back blank). Verify `bundle exec rspec spec/models/client_spec.rb` passes.

## 4. Finalize

- [x] 4.1 Run `bin/rails db:migrate` on a clean development database and `bin/rails db:test:prepare`; verify `db/schema.rb` is regenerated with both migrations and is the only expected diff.
- [x] 4.2 Run `bin/rubocop -A` then `bin/rubocop` and verify zero offenses; run `bin/brakeman -q` and verify zero warnings.
- [x] 4.3 Run the full `bundle exec rspec` suite and verify all examples pass, including the pre-existing `spec/database_connection_spec.rb`.
