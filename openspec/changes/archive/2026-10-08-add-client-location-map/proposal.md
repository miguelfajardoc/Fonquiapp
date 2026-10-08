## Why

A client's location today is a "Ubicación" link that staff paste by hand.
Some links are Google Maps searches and some are short share links. The link
is easy to get wrong, the app cannot show a map with it, and nothing ties it
to the address that was typed. Staff need to see where a client is on the
client's detail page, and to place that point while creating or editing the
client: by typing the address, by clicking on the map, or by both.

## What Changes

- Clients gain optional **latitude and longitude**. Staff never type them;
  they come from a pin on a Google map in the client form.
- **Client form**:
  - The form shows a map to the right of the fields (below them on narrow
    screens).
  - Address and pin follow each other in both directions:
    - **"Ubicar en mapa"** looks up the typed address with Google,
      restricted to Colombia, and drops the pin there. The typed text is
      kept.
    - Clicking the map, or dropping the pin after dragging it, looks up the
      address of that point and **replaces** the address field with it, so
      staff who find the place on the map do not have to type it.
  - A **"Quitar ubicación"** button removes the pin.
  - When the address text is edited by hand while a pin exists, a hint asks
    the user to press "Ubicar en mapa" again.
  - New clients start with the map centered on Bogotá and no pin.
  - When the edit form opens for a client that has an address but no pin
    yet, the address is located automatically. The result is saved only if
    the user saves the form.
- **BREAKING (spec)**: the "Ubicación" (url) field is removed from the form.
  The url is now always generated when the client is saved:
  - When there is a pin, it is a Google Maps link to the pin's coordinates.
  - When there is no pin but there is an address, it is a Google Maps search
    for the address.
  - When there is neither, it is empty.

  Links pasted by hand earlier are replaced the next time the client is
  saved. The index, the detail view and the consolidated xlsx keep showing
  the url, so it always matches the saved location.
- **Client detail view**: an embedded Google map appears to the right of the
  client's data (below it on narrow screens). It shows the pin when there are
  coordinates, and otherwise falls back to a search for the address. It is
  not shown when the client has neither, or when no Google Maps API key is
  configured.
- The Google Maps API key lives in Rails encrypted credentials
  (`google_maps.api_key`). It is never in source code or in plain-text files
  under version control. A missing key disables the maps without errors.

## Capabilities

### New Capabilities
- `client-location`: client coordinates, the url derived from them, the map
  location picker in the client form, and the embedded map on the client
  detail view.

### Modified Capabilities
- `client-directory`: the Client record gains optional latitude and
  longitude. `url` stops being free text and is derived from the location.
- `client-management`: creation and editing no longer accept a url, and the
  form includes the location picker. The detail view adds the embedded map.

## Impact

- **Database**: a migration adds `latitude` and `longitude` (decimal, nullable)
  to `clients`.
- **Model**: `Client` gets coordinate validations (both present or both blank,
  within valid ranges) and a `before_save` that derives `url`.
- **Controller**: `ClientsController#client_params` permits `latitude` and
  `longitude` and stops permitting `url`.
- **Views**:
  - `clients/_form` gets a two-column layout, the map panel and hidden
    coordinate fields.
  - `clients/show` gets the embed iframe.
  - The form passes the key to the browser through a data attribute on the
    picker element.
- **JavaScript**: a new Stimulus `location-picker` controller and a small
  loader for the Google Maps JavaScript API (`maps`, `marker` and
  `geocoding` libraries). No npm or importmap package is added.
- **Configuration**: `config/credentials.yml.enc` holds `google_maps.api_key`
  (already stored) and may hold an optional `google_maps.map_id`.
- **External services**: the Google Cloud project must enable Maps
  JavaScript API, Maps Embed API and Geocoding API. Because the key is used
  in the browser, it should be restricted by HTTP referrer.
- **Seeds and specs**: seeds stop building url by hand. The factory stops
  setting url. Specs that set url explicitly are adjusted.
