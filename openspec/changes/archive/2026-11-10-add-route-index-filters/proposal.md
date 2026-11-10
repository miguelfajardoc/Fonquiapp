## Why

The route index lists every route in one long table, with no way to narrow
it down. Staff need to find a route by its zone, by its name, or by a client
who is one of its stops. The route filter selects on the other index pages
are also hard to use: they offer no routes until a zone is chosen, even when
the user already knows which route they want.

## What Changes

- **Route index filters:** a zone select, a route select, and a client
  combobox (the same single-client search used on the pending product
  creation page). The filters combine, apply as soon as they change, refresh
  only the route list, are kept in the URL, and have a clear-filters
  control. The client filter lists the routes that have the chosen client as
  a stop; each row still shows all of the route's clients.
- **Route index pagination:** at most 20 routes per page, with the same
  pagination controls as the other indexes.
- **Route filter selects list every route when no zone is selected.** This
  applies to the filter bars on the route, client, default product quantity
  and daily product order indexes. Options show the route name only.
  Selecting a zone still narrows the choices to that zone and clears the
  chosen route. Choosing a route never changes the zone select.
- **Not changed:** the route selects inside forms (the default quantity
  creation form and the daily order generation controls) still offer no
  routes until a zone is chosen.

## Capabilities

### New Capabilities

<!-- None -->

### Modified Capabilities

- `route-management`: the route index listing becomes paginated and gains
  zone, route and client filters.
- `client-management`: the client index route filter offers every route
  while no zone is selected.
- `default-product-quantity-management`: the index route filter offers every
  route while no zone is selected.
- `daily-product-order-management`: the batch table route filter offers
  every route while no zone is selected.

## Impact

- **Controllers:** `RoutesController#index` (filters and pagination);
  route filter loading in `ClientsController`,
  `DefaultProductQuantitiesController` and `DailyProductOrdersController`.
- **Models:** `Route` gains filter scopes.
- **Views:** `routes/index` (filter bar, list frame, pagination, empty
  message); the route filter frames of the three other indexes.
- **Locales:** new route index labels in `config/locales/es.yml`.
- **Tests:** request specs for the four indexes; model spec for the route
  filters; a headless-browser check of the route index filters.
- No new dependencies, routes or database changes.
