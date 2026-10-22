require "rails_helper"

RSpec.describe DailyProductOrderConsolidation do
  def rows_for(package)
    package.workbook.worksheets.first.rows.map { |row| row.cells.map(&:value) }
  end

  let(:zone) { create(:zone) }
  let(:route) { create(:route, zone: zone) }

  def stop_client(on_route = route, **attrs)
    create(:client, zone: on_route.zone, **attrs).tap { |client| create(:route_stop, route: on_route, client: client) }
  end

  def batch_order(product:, quantity: 3, on_route: route)
    create(:daily_product_order, zone: on_route.zone, route: on_route, product: product,
                                 day: Date.current, quantity: quantity)
  end

  describe "#call" do
    it "shows only a client's name, address and location hyperlink, with no pending products" do
      client = stop_client(name: "Tienda Norte", address: "Calle 1", latitude: 4.711, longitude: -74.0721)
      product = create(:product, name: "Queso")
      batch_order(product: product, quantity: 4)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 2, state: :pending)
      create(:pending_product, zone: zone, client: client, product: create(:product, name: "Suero"), quantity: 1,
                               state: :pending)

      package = described_class.new(route: route, day: Date.current).call
      rows = rows_for(package)

      expect(rows.first).to eq(%w[Cliente Dirección Ubicación])
      client_row = rows.find { |row| row[0] == "Tienda Norte" }
      expect(client_row).to eq(["Tienda Norte", "Calle 1",
                                %(=HYPERLINK("#{GoogleMaps.search_url("4.711,-74.0721")}","Ver ubicación"))])
      expect(rows.flatten.compact.grep(/Queso: |Suero/)).to be_empty

      location_cell = package.workbook.worksheets.first.rows.find do |row|
        row.cells[0].value == "Tienda Norte"
      end.cells[2]
      expect(location_cell.send(:is_formula?)).to be(true)
    end

    it "lists the route's stop clients in stop position order" do
      stop_client(name: "A")
      stop_client(name: "B")
      client_c = stop_client(name: "C")
      RouteStop.find_by(route: route, client: client_c).insert_at(1)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows.map(&:first) & %w[A B C]).to eq(%w[C A B])
    end

    it "does not include zone clients that are not stops of the route, nor clients from another zone" do
      create(:client, zone: zone, name: "Fuera de Ruta")
      create(:client, zone: create(:zone), name: "Otra Zona")
      stop_client
      batch_order(product: create(:product))

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows.flatten).not_to include("Fuera de Ruta", "Otra Zona")
    end

    it "lists each product of the batch with its quantity, sorted by name" do
      batch_order(product: create(:product, name: "Queso"), quantity: 20)
      batch_order(product: create(:product, name: "Crema"), quantity: 5)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows.last(2)).to eq([["Crema", 5], ["Queso", 20]])
    end

    it "only totals the batch of its own route" do
      other_route = create(:route, zone: zone)
      product = create(:product, name: "Queso")
      batch_order(product: product, quantity: 4)
      batch_order(product: product, quantity: 4, on_route: other_route)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows).to include(["Queso", 4])
    end

    it "reflects the stored batch, not live default data, in the totals table" do
      product = create(:product, name: "Queso")
      batch_order(product: product, quantity: 5)
      default_quantity = create(:default_product_quantity, route: route, product: product, quantity: 5)

      default_quantity.update!(quantity: 99)
      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows).to include(["Queso", 5])
    end
  end
end
