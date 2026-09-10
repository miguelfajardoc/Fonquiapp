# Proyecto

ERP a medida para pequeña empresa. App Rails monolítica.

## Stack
- Ruby 3.4, Rails 8.1.3
- PostgreSQL
- Vistas: ERB + Hotwire (Turbo/Stimulus)
- CSS: TailwindCSS
- Tests: RSpec (rspec-rails, factory_bot, faker)

## Convenciones
- Rubocop con rubocop-rails; correr `bin/rubocop -A` antes de commitear
- Lógica de negocio en modelos o service objects (app/services), no en controladores
- Nombres de rutas RESTful; nada de rutas custom salvo necesidad clara

## Comandos
- Generar: `bin/rails g`
- Migrar: `bin/rails db:migrate`
- Tests: `bundle exec rspec`
- Lint: `bin/rubocop`