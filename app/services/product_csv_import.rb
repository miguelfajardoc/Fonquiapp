# Creates products from a CSV with the columns name and price, or updates the price of an existing product
# whose name matches ignoring case and accents. Prices are digits with an optional decimal point.
class ProductCsvImport < CsvImport
  REQUIRED_HEADERS = %w[name price].freeze
  PRICE_FORMAT = /\A\d+(\.\d+)?\z/

  private

  def import_row(row)
    require_values!(row, "name", "price")
    price = value(row, "price")
    raise RowError, I18n.t("csv_import.errors.invalid_price", price: price) unless price.match?(PRICE_FORMAT)

    save_product(value(row, "name"), price)
  end

  def save_product(name, price)
    product = named(Product.all, "products.name", name).first
    return :updated if product&.update!(price: price)

    Product.create!(name: name, price: price)
    :created
  end
end
