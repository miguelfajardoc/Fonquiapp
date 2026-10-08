## 1. Configuration and data

- [x] 1.1 Store `google_maps.api_key` in `config/credentials.yml.enc`. Verify that `Rails.application.credentials.dig(:google_maps, :api_key)` returns it and that `git grep` finds no plain-text copy of the key.
- [x] 1.2 Add a migration adding `latitude` and `longitude` (`decimal(10, 6)`, nullable) to `clients`. Run it in dev and test. Verify `db/schema.rb` shows both columns.
- [x] 1.3 Add `app/services/google_maps.rb` (`api_key`, `map_id`, `search_url`, `embed_url`). Verify with `spec/services/google_maps_spec.rb`: urls are encoded, the embed url carries the key, and a blank key returns `nil`.

## 2. Model and controller

- [x] 2.1 Add coordinate validations to `Client`: ranges, and both present or both blank. Verify with model specs for valid, incomplete and out-of-range coordinates.
- [x] 2.2 Add a `before_save` that derives `url` from the coordinates, falling back to the address, otherwise `nil`. Verify with model specs for the three cases, plus a hand-pasted link being replaced on save.
- [x] 2.3 In `ClientsController#client_params`, permit `latitude` and `longitude` and drop `url`. Verify with request specs: create and update with coordinates store them and derive url, and a submitted url is ignored.

## 3. Views

- [x] 3.1 Add `app/javascript/lib/google_maps_loader.js` and `pin_all_from "app/javascript/lib"` in importmap. Verify with `bin/importmap json`, which lists `lib/google_maps_loader`.
- [x] 3.2 Add the `location-picker` Stimulus controller: locate (address to pin, keeps the text), click and drag (pin to address, replaces the text), clear, relocate hint, auth-failure message, and auto-locate on edit. Verify in headless Chromium (task 5.2).
- [x] 3.3 Change `clients/_form` to the two-column layout, with the map panel (shown only when a key exists), the hidden coordinate fields, and no url field. Verify with request specs: the new form has the map panel with the Bogotá default and no url field, and there is no map panel without a key.
- [x] 3.4 Change `clients/show` to the data card plus the embed iframe: by coordinates, by address, hidden with neither or with no key. Verify with request specs for each case.
- [x] 3.5 Add Spanish i18n keys (buttons, messages, map titles). Verify that the specs and the browser show the Spanish texts.

## 4. Seeds, factory and existing specs

- [x] 4.1 Remove the hand-built url from `db/seeds.rb` and from `spec/factories/clients.rb`. Stub `GoogleMaps.api_key` globally in `rails_helper`. Adjust specs that set url (clients request specs, consolidation spec, client model spec). Verify with `bundle exec rspec`: the whole suite is green.

## 5. Verification

- [x] 5.1 Run `bin/rubocop` and `openspec validate add-client-location-map --strict`. Both must be clean.
- [x] 5.2 In headless Chromium on port 3001 with the real key:
  - new form centered on Bogotá with no pin;
  - "Ubicar en mapa" places the pin and keeps the typed text;
  - clicking the map, or dragging the pin, places it and fills the address;
  - editing the address by hand shows the relocate hint;
  - "Quitar ubicación" empties the fields;
  - saving stores the coordinates and the url;
  - a rejected key shows the load error;
  - editing a client with an address and no pin auto-locates it.

  Clean up any test data afterwards.
