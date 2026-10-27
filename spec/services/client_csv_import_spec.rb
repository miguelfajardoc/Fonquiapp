require "rails_helper"

RSpec.describe ClientCsvImport do
  def import(rows, header: "name,address,url,phone,zone,route\n")
    described_class.new(StringIO.new((header + rows).b)).call
  end

  before { allow(GoogleMaps).to receive(:redirect_location).and_return(nil) }

  describe "rows" do
    it "creates a client in an existing zone and route, as the route's last stop, matching names loosely" do
      zone = create(:zone, name: "Bosa")
      route = create(:route, zone: zone, name: "Ruta 1")
      2.times { create(:route_stop, route: route, client: create(:client, zone: zone)) }

      result = import("Tienda Norte,Calle 1,,3001234567,bosa,RUTA 1\n")

      client = Client.find_by!(name: "Tienda Norte")
      expect(result.created).to eq(1)
      expect(client).to have_attributes(address: "Calle 1", phone: "3001234567", zone: zone)
      expect(route.reload.clients.last).to eq(client)
      expect(route.route_stops.count).to eq(3)
      expect([Zone.count, Route.count]).to eq([1, 1])
    end

    it "creates a missing zone and route once, even for several rows" do
      import("Tienda A,Calle 1,,,Kennedy,Ruta 5\nTienda B,Calle 2,,,kennedy,ruta 5\n")

      zone = Zone.find_by!(name: "Kennedy")
      expect(Zone.where(name: "Kennedy").count).to eq(1)
      route = zone.routes.find_by!(name: "Ruta 5")
      expect(route.clients.map(&:name)).to eq(["Tienda A", "Tienda B"])
    end

    it "creates a client with no route when the route is blank" do
      import("Tienda A,Calle 1,,,Bosa,\n")

      expect(Client.find_by!(name: "Tienda A").routes).to be_empty
      expect(Route.count).to eq(0)
    end

    it "trims values" do
      import("  Tienda A , Calle 1 ,, 300 ,  Bosa ,\n")

      expect(Client.find_by!(name: "Tienda A")).to have_attributes(address: "Calle 1", phone: "300")
      expect(Zone.pluck(:name)).to eq(["Bosa"])
    end

    it "fails a row missing name, address or zone, creating nothing for it" do
      result = import(",Calle 1,,,Nueva,Ruta X\nTienda B,,,,Nueva,Ruta X\nTienda C,Calle 3,,,,Ruta X\n")

      expect(result.created).to eq(0)
      expect(result.failures).to eq([[2, "falta name"], [3, "falta address"], [4, "falta zone"]])
      expect([Client.count, Zone.count, Route.count]).to eq([0, 0, 0])
    end

    it "fails a row with an existing client's name, ignoring case and accents, without creating its zone" do
      create(:client, name: "Tienda San José")

      result = import("tienda san jose,Calle 1,,,Nueva Zona,Ruta 9\n")

      expect(result.failures).to eq([[2, "Name has already been taken"]])
      expect(Zone.where(name: "Nueva Zona")).to be_empty
      expect(Route.where(name: "Ruta 9")).to be_empty
    end

    it "keeps going after a failed row" do
      result = import("A,Calle 1,,,Bosa,\n,Calle 2,,,Bosa,\nC,Calle 3,,,Bosa,\n")

      expect(result.created).to eq(2)
      expect(Client.pluck(:name)).to contain_exactly("A", "C")
    end

    it "accepts files without the optional url, phone and route columns" do
      result = import("Tienda A,Calle 1,Bosa\n", header: "name,address,zone\n")

      expect(result.created).to eq(1)
    end

    it "rejects a file without the zone column" do
      expect { import("A,Calle 1\n", header: "name,address\n") }
        .to raise_error(CsvImport::InvalidFile, /zone/)
      expect(Client.count).to eq(0)
    end
  end

  describe "location" do
    it "takes the coordinates from a full link" do
      # The link has commas, so it is quoted, as spreadsheets do when exporting.
      import(%(A,Calle 1,"https://www.google.com/maps/place/Tienda/@4.7110,-74.0721,17z",,Bosa,\n))

      client = Client.find_by!(name: "A")
      expect([client.latitude, client.longitude]).to eq([BigDecimal("4.711"), BigDecimal("-74.0721")])
      expect(client.url).to eq(GoogleMaps.search_url("4.711,-74.0721"))
    end

    it "takes the coordinates from a short link's redirect" do
      allow(GoogleMaps).to receive(:redirect_location)
        .and_return("https://www.google.com/maps/place/Tienda/data=!3d4.65!4d-74.1")

      import("A,Calle 1,https://maps.app.goo.gl/AbC123,,Bosa,\n")

      client = Client.find_by!(name: "A")
      expect([client.latitude, client.longitude]).to eq([BigDecimal("4.65"), BigDecimal("-74.1")])
    end

    it "creates the client without a location when the link cannot be read, or there is none" do
      result = import("A,Calle 1,https://maps.app.goo.gl/broken,,Bosa,\n" \
                      "B,Calle 2,https://www.google.com/maps/place/Tienda,,Bosa,\n" \
                      "C,Calle 3,,,Bosa,\n")

      expect(result.created).to eq(3)
      expect(result.failures).to be_empty
      expect(Client.where.not(latitude: nil)).to be_empty
      expect(Client.find_by!(name: "C").url).to eq(GoogleMaps.search_url("Calle 3"))
    end

    it "never requests other hosts" do
      allow(Net::HTTP).to receive(:start)

      import("A,Calle 1,https://example.com/x,,Bosa,\n")

      expect(Net::HTTP).not_to have_received(:start)
      expect(Client.find_by!(name: "A").latitude).to be_nil
    end
  end
end
