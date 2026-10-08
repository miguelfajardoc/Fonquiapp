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

  def batch_order(client:, product:, quantity: 3, on_route: route)
    create(:daily_product_order, zone: on_route.zone, route: on_route, client: client, product: product,
                                 day: Date.current, quantity: quantity)
  end

  describe "#call" do
    it "shows a client's name, address, hyperlink, and current pending products in their own columns" do
      client = stop_client(name: "Tienda Norte", address: "Calle 1", latitude: 4.711, longitude: -74.0721)
      product = create(:product, name: "Queso")
      other_product = create(:product, name: "Mantequilla")
      batch_order(client: client, product: product, quantity: 4)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 2, state: :pending)
      create(:pending_product, zone: zone, client: client, product: other_product, quantity: 1, state: :pending)

      package = described_class.new(route: route, day: Date.current).call
      rows = rows_for(package)

      client_row = rows.find { |row| row[0] == "Tienda Norte" }
      expect(client_row[1]).to eq("Calle 1")
      expect(client_row[2]).to eq(%(=HYPERLINK("#{GoogleMaps.search_url("4.711,-74.0721")}","Ver ubicación")))
      expect(client_row[3..]).to contain_exactly("Queso: 2", "Mantequilla: 1")

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

    it "leaves a client's pending columns blank when they have no current pending products" do
      with_pending = stop_client(name: "Con Pendientes")
      without_pending = stop_client(name: "Sin Pendientes")
      product = create(:product)
      batch_order(client: with_pending, product: product)
      batch_order(client: without_pending, product: product)
      create(:pending_product, zone: zone, client: with_pending, product: product, quantity: 3, state: :pending)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      without_pending_row = rows.find { |row| row[0] == "Sin Pendientes" }
      expect(without_pending_row[3..]).to all(be_nil)
    end

    it "includes every stop client, even one with no default, pending, or daily order" do
      client_with_order = stop_client(name: "Con Orden")
      stop_client(name: "Sin Nada")
      batch_order(client: client_with_order, product: create(:product))

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      idle_row = rows.find { |row| row[0] == "Sin Nada" }
      expect(idle_row).not_to be_nil
      expect(idle_row[3..]).to all(be_nil)
    end

    it "does not include zone clients that are not stops of the route, nor clients from another zone" do
      create(:client, zone: zone, name: "Fuera de Ruta")
      create(:client, zone: create(:zone), name: "Otra Zona")
      batch_order(client: stop_client, product: create(:product))

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows.flatten).not_to include("Fuera de Ruta", "Otra Zona")
    end

    it "sums product quantities across the batch's clients into the totals table" do
      product = create(:product, name: "Queso")
      batch_order(client: stop_client, product: product, quantity: 4)
      batch_order(client: stop_client, product: product, quantity: 3)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows).to include(["Queso", 7])
    end

    it "only totals the batch of its own route" do
      other_route = create(:route, zone: zone)
      product = create(:product, name: "Queso")
      client = stop_client
      create(:route_stop, route: other_route, client: client)
      batch_order(client: client, product: product, quantity: 4)
      batch_order(client: client, product: product, quantity: 4, on_route: other_route)

      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows).to include(["Queso", 4])
    end

    it "reflects the stored batch, not live default/pending data, in the totals table" do
      client = stop_client
      product = create(:product, name: "Queso")
      batch_order(client: client, product: product, quantity: 5)
      default_quantity = create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)

      default_quantity.update!(quantity: 99)
      rows = rows_for(described_class.new(route: route, day: Date.current).call)

      expect(rows).to include(["Queso", 5])
    end
  end
end
