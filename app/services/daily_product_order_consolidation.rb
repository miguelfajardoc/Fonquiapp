class DailyProductOrderConsolidation
  FIXED_HEADERS = %w[Cliente Dirección Ubicación].freeze

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
    clients = @route.route_stops.includes(:client).map(&:client)
    pending_by_client = clients.index_with { |client| current_pending_products(client) }
    max_pending = pending_by_client.values.map(&:size).max || 0

    sheet.add_row(FIXED_HEADERS + pending_headers(max_pending))
    clients.each { |client| add_client_row(sheet, client, pending_by_client[client], max_pending) }
  end

  def add_product_totals(sheet, orders)
    sheet.add_row([])
    sheet.add_row(%w[Producto Cantidad])
    product_totals(orders).each { |name, quantity| sheet.add_row([name, quantity]) }
  end

  def batch_orders
    DailyProductOrder.where(route: @route, day: @day).includes(:client, :product)
  end

  def current_pending_products(client)
    client.pending_products.where(state: :pending).includes(:product).order(:created_at)
  end

  def pending_headers(count)
    (1..count).map { |n| "Pendiente #{n}" }
  end

  def add_client_row(sheet, client, pending_products, max_pending)
    values, escape_formulas = client_row(client, pending_products, max_pending)
    sheet.add_row(values, escape_formulas: escape_formulas)
  end

  def client_row(client, pending_products, max_pending)
    location_formula = client.url.present?
    values = [client.name, client.address, location_value(client, location_formula)]
    escape_formulas = [true, true, !location_formula]

    append_pending_cells(values, escape_formulas, pending_products, max_pending)

    [values, escape_formulas]
  end

  def append_pending_cells(values, escape_formulas, pending_products, max_pending)
    pending_products.each do |pending_product|
      values << "#{pending_product.product.name}: #{pending_product.quantity}"
      escape_formulas << true
    end

    (pending_products.size...max_pending).each do
      values << nil
      escape_formulas << true
    end
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
