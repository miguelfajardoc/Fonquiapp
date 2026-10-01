## MODIFIED Requirements

### Requirement: Route deletion with confirmation

The system SHALL require explicit confirmation, presented as a prompt with a
cancel option and a confirm option, before deleting a route. The system
SHALL NOT delete the route unless the confirm option is chosen. When the
route cannot be deleted because daily product orders reference it, the
system SHALL keep the route, return the user to the route index, and show
an error explaining why it was not deleted.

#### Scenario: Confirmation is required before deletion

- **GIVEN** a route exists
- **WHEN** the delete control is chosen for that route
- **THEN** a confirmation prompt is shown with a cancel option and a
  confirm option
- **AND** the route still exists until the confirm option is chosen

#### Scenario: Canceling the confirmation keeps the route

- **GIVEN** a route exists and its delete confirmation prompt is open
- **WHEN** the cancel option is chosen
- **THEN** the route still exists
- **AND** no deletion is attempted

#### Scenario: Confirming deletion removes the route and its stops

- **GIVEN** a route with two client stops and no daily product orders
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the route and both of its stops are deleted
- **AND** the route no longer appears on the index

#### Scenario: Deleting a route with daily product orders shows an error

- **GIVEN** a route referenced by a daily product order
- **WHEN** the confirm option is chosen on its delete confirmation prompt
- **THEN** the route and its stops still exist
- **AND** the user is returned to the route index with an error explaining
  the route could not be deleted
