require "rails_helper"

RSpec.describe DailyProductOrderConsolidation do
  def rows_for(package)
    package.workbook.worksheets.first.rows.map { |row| row.cells.map(&:value) }
  end

  describe "#call" do
    it "shows a client's name, address, hyperlink, and current pending products in their own columns" do
      zone = create(:zone)
      client = create(:client, zone: zone, name: "Tienda Norte", address: "Calle 1", url: "https://maps.example/1")
      product = create(:product, name: "Queso")
      other_product = create(:product, name: "Mantequilla")
      create(:daily_product_order, zone: zone, client: client, product: product, day: Date.current, quantity: 4)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 2, state: :pending)
      create(:pending_product, zone: zone, client: client, product: other_product, quantity: 1, state: :pending)

      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      client_row = rows.find { |row| row[0] == "Tienda Norte" }
      expect(client_row[1]).to eq("Calle 1")
      expect(client_row[2]).to eq('=HYPERLINK("https://maps.example/1","Ver ubicación")')
      expect(client_row[3..]).to contain_exactly("Queso: 2", "Mantequilla: 1")

      location_cell = package.workbook.worksheets.first.rows.find do |row|
        row.cells[0].value == "Tienda Norte"
      end.cells[2]
      expect(location_cell.send(:is_formula?)).to be(true)
    end

    it "leaves a client's pending columns blank when they have no current pending products" do
      zone = create(:zone)
      with_pending = create(:client, zone: zone, name: "Con Pendientes")
      without_pending = create(:client, zone: zone, name: "Sin Pendientes")
      product = create(:product)
      create(:daily_product_order, zone: zone, client: with_pending, product: product, day: Date.current)
      create(:daily_product_order, zone: zone, client: without_pending, product: product, day: Date.current)
      create(:pending_product, zone: zone, client: with_pending, product: product, quantity: 3, state: :pending)

      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      without_pending_row = rows.find { |row| row[0] == "Sin Pendientes" }
      expect(without_pending_row[3..]).to all(be_nil)
    end

    it "includes every client in the zone, even one with no default, pending, or daily order" do
      zone = create(:zone)
      client_with_order = create(:client, zone: zone, name: "Con Orden")
      create(:client, zone: zone, name: "Sin Nada")
      product = create(:product)
      create(:daily_product_order, zone: zone, client: client_with_order, product: product, day: Date.current)

      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      idle_row = rows.find { |row| row[0] == "Sin Nada" }
      expect(idle_row).not_to be_nil
      expect(idle_row[3..]).to all(be_nil)
    end

    it "does not include a client from a different zone" do
      zone = create(:zone)
      other_zone = create(:zone)
      create(:client, zone: other_zone, name: "Otra Zona")
      product = create(:product)
      create(:daily_product_order, zone: zone, client: create(:client, zone: zone), product: product, day: Date.current)

      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      expect(rows.flatten).not_to include("Otra Zona")
    end

    it "sums product quantities across the batch's clients into the totals table" do
      zone = create(:zone)
      client_a = create(:client, zone: zone)
      client_b = create(:client, zone: zone)
      product = create(:product, name: "Queso")
      create(:daily_product_order, zone: zone, client: client_a, product: product, day: Date.current, quantity: 4)
      create(:daily_product_order, zone: zone, client: client_b, product: product, day: Date.current, quantity: 3)

      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      expect(rows).to include(["Queso", 7])
    end

    it "reflects the stored batch, not live default/pending data, in the totals table" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product, name: "Queso")
      create(:daily_product_order, zone: zone, client: client, product: product, day: Date.current, quantity: 5)
      default_quantity = create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)

      default_quantity.update!(quantity: 99)
      package = described_class.new(zone: zone, day: Date.current).call
      rows = rows_for(package)

      expect(rows).to include(["Queso", 5])
    end
  end
end
