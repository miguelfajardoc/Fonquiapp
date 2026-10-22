class DailyProductOrderConsolidation
  CLIENT_HEADERS = %w[Cliente Dirección Ubicación].freeze

  def initialize(route:, day:)
    @route = route
    @day = day
  end

  def call
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Consolidado") { |sheet| build_sheet(sheet) }
    package
  end

  private

  def build_sheet(sheet)
    add_client_table(sheet)
    add_product_totals(sheet, batch_orders)
  end

  def add_client_table(sheet)
    sheet.add_row(CLIENT_HEADERS)
    @route.route_stops.includes(:client).map(&:client).each { |client| add_client_row(sheet, client) }
  end

  def add_product_totals(sheet, orders)
    sheet.add_row([])
    sheet.add_row(%w[Producto Cantidad])
    product_totals(orders).each { |name, quantity| sheet.add_row([name, quantity]) }
  end

  def batch_orders
    DailyProductOrder.where(route: @route, day: @day).includes(:product)
  end

  def add_client_row(sheet, client)
    location_formula = client.url.present?
    sheet.add_row([client.name, client.address, location_value(client, location_formula)],
                  escape_formulas: [true, true, !location_formula])
  end

  def location_value(client, formula)
    return client.url unless formula

    "=HYPERLINK(\"#{client.url}\",\"Ver ubicación\")"
  end

  def product_totals(orders)
    orders.group_by { |order| order.product.name }
          .transform_values { |group| group.sum(&:quantity) }
          .sort_by { |name, _quantity| name }
  end
end
