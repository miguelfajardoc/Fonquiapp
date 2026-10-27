# product-import Specification

## Purpose

Product import lets staff load or refresh many catalog products at once from
a comma-separated CSV file on the product index, updating the price of
products that already exist and reporting which rows could not be loaded.

## Requirements

### Requirement: Product import control

The product index SHALL display a "Cargar productos" control immediately to
the right of the "Crear producto" control. Choosing it SHALL open the
browser's standard file picker limited to `.csv` files, and choosing a file
SHALL start the import right away, without a separate submit step. When the
import finishes, the user SHALL be returned to the product index with the
result shown as flash messages.

#### Scenario: The control sits to the right of the create control

- **WHEN** the product index is viewed
- **THEN** a "Cargar productos" control is displayed immediately to the right
  of the "Crear producto" control

#### Scenario: Choosing a file starts the import

- **GIVEN** the product index is open
- **WHEN** "Cargar productos" is chosen and a `.csv` file is picked in the
  file picker
- **THEN** the file is imported without any further action
- **AND** the product index is shown again with the import result

### Requirement: Product CSV file format

The system SHALL accept a comma-separated file whose first row is a header
naming the columns `name` and `price`. Headers SHALL be matched ignoring
letter case and surrounding spaces, and columns MAY appear in any order;
other columns SHALL be ignored. The file SHALL be read as UTF-8 (a leading
byte-order mark is ignored), falling back to Windows-1252 when it is not
valid UTF-8. Blank lines SHALL be ignored. When no file is chosen, the file
cannot be parsed as CSV, or its header lacks `name` or `price`, the system
SHALL create or change nothing and SHALL show an error saying why.

#### Scenario: A file without a required column is rejected

- **GIVEN** a file whose header has `name` but no `price`
- **WHEN** it is imported
- **THEN** no product is created or changed
- **AND** an error says the `price` column is missing

#### Scenario: Headers match regardless of case and order

- **GIVEN** a file whose header is `Price, NAME`
- **WHEN** it is imported with the row `2500,Queso`
- **THEN** product "Queso" with price 2500.00 exists

### Requirement: Creating and updating products from rows

For each data row, the system SHALL read `name` and `price`, trimmed of
surrounding spaces; both SHALL be required. `price` SHALL be a non-negative
number written with digits and an optional decimal point (for example
`12500` or `12500.50`); any other value SHALL make the row fail. When an
existing product's name matches the row's name ignoring letter case and
accents, the system SHALL update that product's price and keep its name;
otherwise it SHALL create a new product with that name and price.

#### Scenario: A new product is created

- **GIVEN** no product named "Arequipe" exists
- **WHEN** a file with the row `Arequipe,8500` is imported
- **THEN** product "Arequipe" is created with price 8500.00

#### Scenario: An existing product's price is updated

- **GIVEN** product "Queso" exists with price 10000.00
- **WHEN** a file with the row `queso,12000.5` is imported
- **THEN** no new product is created
- **AND** product "Queso" keeps its name and has price 12000.50

#### Scenario: A row missing a value fails

- **WHEN** a file with a row whose `name` or `price` is blank is imported
- **THEN** no product is created or changed for that row
- **AND** the row is reported as failed, naming the missing value

#### Scenario: A row with an invalid price fails

- **WHEN** a file with a row whose price is `-5`, `abc`, or `12.500,00` is
  imported
- **THEN** no product is created or changed for that row
- **AND** the row is reported as failed because the price is invalid

### Requirement: Product import result

Every row SHALL be processed independently: a failed row SHALL NOT prevent
the rows before or after it from being processed. After the import, the
system SHALL show a notice with the number of products created and the number
updated, and, when any row failed, an alert listing each failed row by its
line number in the file (the header is line 1) with the reason it failed. The
alert SHALL list at most 20 failed rows and SHALL say how many more failed
beyond those.

#### Scenario: Mixed results are reported

- **GIVEN** product "Queso" exists
- **WHEN** a file is imported whose rows are a new product, "Queso" with a
  new price, and a row on line 4 with no price
- **THEN** a notice says 1 product was created and 1 was updated
- **AND** an alert lists line 4 with its reason

#### Scenario: All rows valid

- **WHEN** a file with only valid rows is imported
- **THEN** a notice says how many products were created and updated
- **AND** no alert is shown
