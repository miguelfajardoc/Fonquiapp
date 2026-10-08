## Context

- `clients` has `address` (free text, typed Colombian-style such as
  "Calle 22 # 1-78, Bogotá y alrededores") and `url`. Staff fill `url` by
  hand today; the values are a mix of Google Maps search links and
  `maps.app.goo.gl` short links. The consolidated xlsx uses it as
  `=HYPERLINK(url, "Ver ubicación")`.
- The frontend uses importmap and Stimulus with no bundler. CSP is not
  enabled. `config/credentials.yml.enc` (a single file for every environment)
  now holds `google_maps.api_key`. `config/master.key` is gitignored.
- The user enabled a single Google Maps key. It is used from the browser
  (the JS map and the Embed iframe).

## Goals / Non-Goals

**Goals:**
- Coordinates come only from the pin. The url is derived from the location,
  so it can never contradict it.
- Nothing calls Google from the server, and no job is needed. One key,
  restricted by HTTP referrer, is enough.
- Missing key in any environment means no maps and no errors.

**Non-Goals:**
- Address autocomplete (Places API). The "Ubicar en mapa" button with the
  Geocoding service was chosen instead.
- Bulk geocoding of existing clients. They get a pin when they are edited.
- Maps anywhere other than the client form and the client detail view (for
  example, route maps).

## Decisions

### D1. Geocoding runs in the browser, not on the server
The form's Stimulus controller calls `google.maps.Geocoder` with
`{ address, region: "co", componentRestrictions: { country: "CO" } }`.
- **Alternative:** a server-side job calling the Geocoding web service on
  save. Rejected: the user places or confirms the pin visually anyway. A
  server call would need a second key without referrer restrictions (or an
  IP-restricted one), plus a running Solid Queue in dev.

### D2. `GoogleMaps` module as the single place that knows Google
`app/services/google_maps.rb` holds:
- `api_key` and `map_id`, both read from
  `Rails.application.credentials.dig(:google_maps, ...)` with `.presence`;
- `search_url(query)`, which returns
  `https://www.google.com/maps/search/?api=1&query=<encoded>`, Google's
  documented Maps URLs format;
- `embed_url(query)`, which returns
  `https://www.google.com/maps/embed/v1/place?key=…&q=…&language=es&region=CO`.

Specs stub `GoogleMaps.api_key`. `rails_helper` stubs it to a fake value
for every example, so tests never render the real key, and examples that
check the no-key path stub it to `nil`.

### D3. Url derived in a `before_save` on `Client`
- With coordinates: `search_url("#{lat},#{lng}")`, using BigDecimal
  `to_s("F")` so there is no scientific notation.
- With only an address: `search_url(address)`.
- Otherwise: `nil`.

Because this runs on every save, hand-pasted links are replaced the next
time a client is saved. `url` is removed from the permitted params and from
the form. The index, the show page and the xlsx keep reading `client.url`
unchanged.

### D4. Coordinates columns and validation
- `latitude` and `longitude` are `decimal(10, 6)` and nullable. Six decimals
  is about 0.1 m.
- The JS rounds positions to 6 decimals before writing the hidden fields.
- Validations:
  - `numericality` in -90..90 and -180..180, `allow_nil`;
  - a custom check that both coordinates are present or both blank.

Blank hidden fields cast to `nil`.

### D5. Embed API iframe on the show page; Maps JavaScript API in the form
- **Show page:** an `<iframe>` with `embed_url`, `loading="lazy"` and
  `referrerpolicy="no-referrer-when-downgrade"`. That referrer policy is what
  Google needs for referrer-restricted keys. Embed loads are free and
  unlimited, and the page needs no JS.
  - The query is `"lat,lng"` when the client has coordinates.
  - Otherwise it is the address.
  - The frame is omitted when there is neither, or when there is no key.
- **Form:** needs interaction (click, drag, geocode), so it uses the JS API.

### D6. Loading the JS API without a package
`app/javascript/lib/google_maps_loader.js` exports `loadGoogleMaps(apiKey)`.
- On first use it injects
  `https://maps.googleapis.com/maps/api/js?key=…&v=weekly&loading=async&language=es&region=CO&callback=…`.
- It caches the promise, so Turbo navigations reuse the loaded API.
- `config/importmap.rb` gets `pin_all_from "app/javascript/lib", under: "lib"`.
- Libraries are fetched with `google.maps.importLibrary("maps" | "marker" | "geocoding")`.
- **Alternative:** the `@googlemaps/js-api-loader` npm package through
  importmap. Rejected: it is extra vendored code for about 20 lines of
  loader.

### D7. AdvancedMarkerElement with a map id
The legacy `google.maps.Marker` is deprecated. `AdvancedMarkerElement`
requires a map id, so the map uses `google_maps.map_id` from credentials
when it is set, and Google's `DEMO_MAP_ID` otherwise. It is draggable
(`gmpDraggable: true`).

### D8. `location-picker` Stimulus controller
- **Values:**
  - `apiKey` and `mapId`;
  - `autoLocate`: true when the client has an address and no coordinates;
  - message strings for i18n, passed from the view.
- **Targets:**
  - `map`;
  - `latitude` and `longitude` (the hidden form fields);
  - `address` (the existing address input);
  - `status` (the "not found" messages, the relocate hint, and the load
    error).
- **Address to pin (`locate`):** forward geocode with
  `{ address, region: "co", componentRestrictions: { country: "CO" } }`. It
  moves the pin and keeps the typed text.
- **Pin to address:** a map `click` and the marker's `gmp-dragend` call
  `pinFromMap`. It moves the pin, reverse geocodes with `{ location }`, and
  writes `results[0].formatted_address` into the address field, replacing it
  (user decision). The result is in Spanish because the API loads with
  `language=es`.
- **Stale results:** a lookup counter drops any response that arrives after
  a newer click, drag, locate or clear.
- **Keeping text and pin in step:** `syncedAddress` holds the text that
  matches the pin:
  - after `locate`, the typed text;
  - after a reverse lookup, the returned address;
  - on edit, the saved address.

  On `input` in the address field, the relocate hint is shown while a pin
  exists and the text differs from `syncedAddress`.
- **Removed:** an earlier draft had a 300 m "pin far from the address"
  warning. Once the address follows the pin, the two cannot drift apart
  silently, so the warning was removed.
- **Default view:** centered on Bogotá (`4.711, -74.0721`) at zoom 12, or on
  the pin at zoom 16.
- **`connect`** empties the map target first, so a Turbo cache snapshot does
  not leave a dead map clone. The loader sets `window.gm_authFailure`, so a
  rejected key (wrong referrer, API disabled) shows "No se pudo cargar el
  mapa".
- **No key:** the view omits the map panel. The hidden fields stay in the
  form, so saved coordinates are kept.

### D9. Layout
- **Form:** a `grid gap-6 lg:grid-cols-[24rem_1fr]`.
  - Left: the existing fields.
  - Right: the map panel (map about 24rem tall, the two buttons, the status
    line).
  - Bottom: the actions row spanning both columns.
- **Show page:** the same split: the data card on the left and the iframe on
  the right. They stack on mobile.
- "Ubicar en mapa" sits in the map panel next to "Quitar ubicación", so all
  map controls are together.

## Risks / Trade-offs

- **[Risk]** The key is visible in the page source.
  **Mitigation:** the user restricts it by HTTP referrer (localhost:3000,
  localhost:3001 and the production domain) and to the three APIs. It lives
  only in encrypted credentials.
- **[Risk]** Geocoding Colombian addresses can land on the street rather
  than the house number. Reverse geocoding can return Google's formatting
  (for example "Ak 14 #3233, Bogotá, Colombia").
  **Mitigation:** the pin is draggable, and the address text stays editable
  after it is filled.
- **[Risk]** `DEMO_MAP_ID` is meant for development.
  **Mitigation:** add a real `google_maps.map_id` in credentials before
  production. No code change is needed.
- **[Trade-off]** Every save rewrites `url`, so hand-pasted short links are
  lost on the next save. This is accepted by the user decision that the url
  must always match the location.
- **[Risk]** Request specs cannot exercise the JS map.
  **Mitigation:** verify the form in headless Chromium against the real key
  on the temporary server (port 3001).

## Migration Plan

1. Migration adds the two nullable columns. It is reversible and touches no
   existing data.
2. Deploy needs `RAILS_MASTER_KEY` (already required) and the Google Cloud
   APIs enabled.
3. Rollback: revert the code and roll the migration back. Urls generated
   meanwhile stay valid Google Maps links.
