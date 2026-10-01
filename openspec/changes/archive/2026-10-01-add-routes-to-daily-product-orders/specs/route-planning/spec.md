## MODIFIED Requirements

### Requirement: Referential integrity on delete

A zone that is referenced by any route SHALL NOT be deletable. A client that
is referenced by any route stop SHALL NOT be deletable. A route that is
referenced by any daily product order SHALL NOT be deletable. Deleting a
route that no daily product order references SHALL delete its route stops
along with it, since a route stop has no meaning outside the route that
ordered it.

#### Scenario: A referenced zone cannot be deleted

- **GIVEN** a zone referenced by a route
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is not deleted and still exists

#### Scenario: A referenced client cannot be deleted

- **GIVEN** a client referenced by a route stop
- **WHEN** deletion of that client is attempted
- **THEN** the client is not deleted and still exists

#### Scenario: Deleting a route deletes its route stops

- **GIVEN** a route with two route stops and no daily product orders
- **WHEN** that route is deleted
- **THEN** the route and both of its route stops no longer exist

#### Scenario: A route referenced by a daily product order cannot be deleted

- **GIVEN** a route with route stops that is referenced by a daily product order
- **WHEN** deletion of that route is attempted
- **THEN** the route is not deleted and still exists
- **AND** its route stops still exist

#### Scenario: An unreferenced zone can still be deleted

- **GIVEN** a zone that no route references
- **WHEN** deletion of that zone is attempted
- **THEN** the zone is removed
