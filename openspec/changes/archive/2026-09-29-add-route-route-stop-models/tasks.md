## 1. Dependency and schema

- [x] 1.1 Add `gem "acts_as_list"` to the main section of the `Gemfile` and run `bundle install`; verify `Gemfile.lock` gains the gem with no errors
- [x] 1.2 Generate a migration creating `routes` (`name:string`, `zone:references`) and `route_stops` (`route:references`, `client:references`, `position:integer`), plus the unique indexes on `routes(zone_id, name)` and `route_stops(route_id, client_id)` per design.md; run `bin/rails db:migrate` and verify `db/schema.rb` reflects both tables with their indexes and foreign keys

## 2. Models

- [x] 2.1 Create `app/models/route.rb` with `belongs_to :zone`, `has_many :route_stops, dependent: :destroy`, `has_many :clients, through: :route_stops`, and `validates :name, presence: true, uniqueness: { scope: :zone_id }`
- [x] 2.2 Create `app/models/route_stop.rb` with `belongs_to :route`, `belongs_to :client`, `acts_as_list scope: :route`, and `validates :client_id, uniqueness: { scope: :route_id }`
- [x] 2.3 Add `has_many :routes, dependent: :restrict_with_error` to `app/models/zone.rb` and `has_many :route_stops, dependent: :restrict_with_error` to `app/models/client.rb`; verify `bin/rails runner "Route; RouteStop"` loads both models without error

## 3. Factories and model specs

- [x] 3.1 Add `spec/factories/routes.rb` (sequenced `name`, `association :zone`) and `spec/factories/route_stops.rb` (`association :route`, `association :client`)
- [x] 3.2 Write `spec/models/route_spec.rb` covering every scenario in `specs/route-planning/spec.md` for the Route record (creation, name presence, per-zone name uniqueness, name reuse across zones, zone presence and referential integrity) and the route-to-client relationship (clients listed in stop order)
- [x] 3.3 Write `spec/models/route_stop_spec.rb` covering every scenario in `specs/route-planning/spec.md` for the RouteStop record (creation, route/client presence and referential integrity, per-route client uniqueness, same client allowed in different routes) and position ordering (append on create, gap-closing on destroy, reordering with `insert_at` shifts only that route's stops, independence between two routes' position sequences)
- [x] 3.4 Write or extend specs covering referential integrity on delete (`Zone` and `Client` deletion blocked while referenced; deleting a `Route` deletes its `RouteStop`s) and run `bundle exec rspec spec/models/route_spec.rb spec/models/route_stop_spec.rb spec/models/zone_spec.rb spec/models/client_spec.rb`, verifying all examples pass (35 examples, 0 failures)

## 4. Seeds

- [x] 4.1 Update `db/seeds.rb` to `find_or_create_by!` one or two routes per zone and regenerate (`delete_all` then recreate) each route's stops from a shuffled sample of that zone's clients, per design.md
- [x] 4.2 Run `bin/rails db:seed` twice in a row against a fresh development database and verify it completes both times with no errors and no duplicate routes

## 5. Full verification

- [x] 5.1 Run the full test suite with `bundle exec rspec` and verify there are no failures or regressions in existing specs (160 examples, 0 failures)
- [x] 5.2 Run `openspec validate add-route-route-stop-models --strict` and verify it passes
