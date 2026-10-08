## Purpose

Client location lets staff place each client as a point on a Google map while
creating or editing the client, either by locating the typed address or by
placing the pin by hand, and see that point on the client's detail view. The
client's location link is always derived from the saved location, so it is
consistent everywhere it is shown.

## ADDED Requirements

### Requirement: Client coordinates

The system SHALL store an optional latitude and longitude for each client.
Both SHALL be present or both SHALL be blank. Latitude SHALL be between -90
and 90 and longitude between -180 and 180. Staff SHALL NOT type coordinates
directly; they come only from the pin on the client form's map.

#### Scenario: Client saved with a pin

- **WHEN** a client is saved with latitude 4.711 and longitude -74.0721
- **THEN** the client is persisted with those coordinates

#### Scenario: Client saved without a pin

- **WHEN** a client is saved with no latitude and no longitude
- **THEN** the client is persisted with blank coordinates

#### Scenario: Incomplete or out-of-range coordinates are rejected

- **WHEN** a client is saved with a latitude but no longitude, or with a
  latitude of 95
- **THEN** the client is not persisted
- **AND** a validation error is reported

### Requirement: Location link derived from the location

The system SHALL generate the client's location link (url) every time the
client is saved, and SHALL NOT accept a url submitted by the user:

- with coordinates, the link SHALL be a Google Maps link to those coordinates;
- without coordinates but with an address, the link SHALL be a Google Maps
  search for that address;
- with neither, the link SHALL be empty.

#### Scenario: Link points at the coordinates

- **WHEN** a client with address "Calle 1" is saved with latitude 4.711 and
  longitude -74.0721
- **THEN** its url is a Google Maps link to "4.711,-74.0721"

#### Scenario: Link searches the address when there is no pin

- **WHEN** a client with address "Calle 22 # 1-78, Bogotá" is saved with no
  coordinates
- **THEN** its url is a Google Maps search for "Calle 22 # 1-78, Bogotá"

#### Scenario: No address and no pin leave the link empty

- **WHEN** a client is saved with no address and no coordinates
- **THEN** its url is empty

#### Scenario: A submitted url is ignored

- **GIVEN** a client with address "Calle 1" and no coordinates
- **WHEN** the client form is submitted with a url "https://example.test"
- **THEN** the client's url is the Google Maps search for "Calle 1"

#### Scenario: A previously pasted link is replaced on save

- **GIVEN** a client whose url is a hand-pasted short link
- **WHEN** the client is saved again
- **THEN** its url is regenerated from its current location

### Requirement: Location picker in the client form

The client creation and editing forms SHALL show a Google map beside the
client fields (to their right on wide screens, below them on narrow
screens), with at most one pin marking the client's location, and SHALL
submit the pin's coordinates with the form. Address and pin SHALL be kept in
step in both directions:

- **Address to pin:** choosing **"Ubicar en mapa"** SHALL look up the typed
  address, restricted to Colombia, and place the pin on the first result,
  centering the map on it, keeping the typed address text unchanged. When the
  address is blank or is not found, the pin SHALL stay where it was and a
  message SHALL say the address could not be located.
- **Pin to address:** clicking the map SHALL place the pin at the clicked
  point, and the pin SHALL be draggable. Every time the pin is placed or
  dropped this way, the address of that point SHALL be looked up and SHALL
  replace the address field's text, whatever it held before. When no address
  is found for the point, the pin SHALL stay, the address text SHALL be left
  unchanged, and a message SHALL say no address was found for that point.
- Choosing **"Quitar ubicación"** SHALL remove the pin, so the client is
  saved without coordinates; the address text is left unchanged.
- Editing the address text by hand SHALL NOT move the pin on its own. While a
  pin exists and the address text differs from the one that matches the pin,
  a hint SHALL ask the user to choose "Ubicar en mapa".
- On the creation form the map SHALL start centered on Bogotá with no pin.
- On the editing form the map SHALL show the client's saved pin. When the
  client has an address but no saved pin, the address SHALL be located
  automatically and the pin placed, and it SHALL be stored only if the form
  is saved.
- When no Google Maps API key is configured, the form SHALL work without the
  map, keeping any saved coordinates unchanged.

#### Scenario: New client form starts on Bogotá without a pin

- **WHEN** the new-client form is opened
- **THEN** a map centered on Bogotá is shown
- **AND** no pin is placed and the coordinate fields are empty

#### Scenario: Locating the typed address places the pin

- **GIVEN** the client form is open and the address "Calle 26 # 68-35,
  Bogotá" is typed
- **WHEN** "Ubicar en mapa" is chosen
- **THEN** the pin is placed on the address found in Colombia
- **AND** the coordinate fields hold the pin's position
- **AND** the address text is still "Calle 26 # 68-35, Bogotá"

#### Scenario: Address that cannot be located

- **GIVEN** the client form is open with a blank address, or an address
  that is not found
- **WHEN** "Ubicar en mapa" is chosen
- **THEN** the pin does not move
- **AND** a message says the address could not be located

#### Scenario: Placing the pin on the map fills the address

- **GIVEN** the client form is open, with or without address text
- **WHEN** the map is clicked, or an existing pin is dragged and dropped
- **THEN** the pin is at that point and the coordinate fields hold it
- **AND** the address field holds the address found for that point,
  replacing any previous text

#### Scenario: Point without an address

- **GIVEN** the client form is open
- **WHEN** the pin is placed on a point for which no address is found
- **THEN** the pin and coordinate fields hold that point
- **AND** the address text is unchanged
- **AND** a message says no address was found for that point

#### Scenario: Removing the pin

- **GIVEN** the client form shows a pin
- **WHEN** "Quitar ubicación" is chosen and the form is saved
- **THEN** the client is saved without coordinates

#### Scenario: Editing the address by hand asks to relocate

- **GIVEN** the client form shows a pin matching the address text
- **WHEN** the address text is changed by hand
- **THEN** the pin does not move
- **AND** a hint asks to choose "Ubicar en mapa"

#### Scenario: Editing a client with a saved pin

- **GIVEN** a client with saved coordinates
- **WHEN** its edit form is opened
- **THEN** the map shows the pin at those coordinates

#### Scenario: Editing a client with an address but no pin

- **GIVEN** a client with an address and no coordinates
- **WHEN** its edit form is opened
- **THEN** the address is located and the pin placed
- **AND** the client's stored coordinates change only if the form is saved

### Requirement: Embedded map on the client detail view

The client detail view SHALL show an embedded Google map beside the client's
data (to its right on wide screens, below it on narrow screens). With
coordinates the map SHALL mark them; without coordinates but with an address
it SHALL show a Google search for the address in Colombia. The map SHALL NOT
be shown when the client has neither, or when no Google Maps API key is
configured.

#### Scenario: Client with coordinates

- **GIVEN** a client with saved coordinates
- **WHEN** its detail view is shown
- **THEN** an embedded map marks those coordinates

#### Scenario: Client with only an address

- **GIVEN** a client with an address and no coordinates
- **WHEN** its detail view is shown
- **THEN** an embedded map searches for that address

#### Scenario: Client without location

- **GIVEN** a client with no address and no coordinates
- **WHEN** its detail view is shown
- **THEN** no map is shown

#### Scenario: No API key configured

- **GIVEN** no Google Maps API key is configured
- **WHEN** any client's detail view is shown
- **THEN** no map is shown and the page renders normally

### Requirement: API key kept out of source control

The Google Maps API key SHALL be read from the application's encrypted
credentials and SHALL NOT appear in source code or in any plain-text file
under version control.

#### Scenario: Key comes from encrypted credentials

- **GIVEN** the key is stored in the encrypted credentials
- **WHEN** a page with a map is rendered
- **THEN** the map uses that key
- **AND** no tracked plain-text file contains the key
