require "rails_helper"

RSpec.describe Client, type: :model do
  describe "validations" do
    it "is valid with a name and a zone" do
      expect(build(:client, name: "ACME", zone: create(:zone))).to be_valid
    end

    it "is invalid without a name" do
      client = build(:client, name: "")
      expect(client).not_to be_valid
      expect(client.errors[:name]).to be_present
    end

    it "is invalid without a zone" do
      client = build(:client, zone: nil)
      expect(client).not_to be_valid
      expect(client.errors[:zone]).to be_present
    end
  end

  describe "optional contact details" do
    it "persists without address, phone or location, leaving the url empty" do
      client = build(:client, address: nil, phone: nil, latitude: nil, longitude: nil)

      expect(client.save).to be(true)
      client.reload
      expect(client.address).to be_nil
      expect(client.url).to be_nil
      expect(client.phone).to be_nil
      expect(client.latitude).to be_nil
    end
  end

  describe "coordinates" do
    it "persists a complete pin" do
      client = create(:client, latitude: 4.711, longitude: -74.0721)

      expect([client.reload.latitude, client.longitude]).to eq([BigDecimal("4.711"), BigDecimal("-74.0721")])
    end

    it "is invalid with only one coordinate" do
      expect(build(:client, latitude: 4.711, longitude: nil)).not_to be_valid
      expect(build(:client, latitude: nil, longitude: -74.0721)).not_to be_valid
    end

    it "is invalid with out-of-range coordinates" do
      expect(build(:client, latitude: 95, longitude: -74)).not_to be_valid
      expect(build(:client, latitude: 4.7, longitude: -181)).not_to be_valid
    end
  end

  describe "derived url" do
    it "links to the coordinates when the client has a pin" do
      client = create(:client, address: "Calle 1", latitude: 4.711, longitude: -74.0721)

      expect(client.url).to eq("https://www.google.com/maps/search/?api=1&query=4.711%2C-74.0721")
    end

    it "searches the address when there is no pin" do
      client = create(:client, address: "Calle 22 # 1-78, Bogotá", latitude: nil, longitude: nil)

      expect(client.url).to eq(GoogleMaps.search_url("Calle 22 # 1-78, Bogotá"))
    end

    it "replaces a hand-pasted link the next time the client is saved" do
      client = create(:client, address: "Calle 1")
      client.update_column(:url, "https://maps.app.goo.gl/abc") # rubocop:disable Rails/SkipsModelValidations

      client.update!(phone: "555")

      expect(client.url).to eq(GoogleMaps.search_url("Calle 1"))
    end
  end

  describe "#zone" do
    it "reports the zone it belongs to" do
      zone = create(:zone)
      expect(create(:client, zone: zone).zone).to eq(zone)
    end
  end

  describe "deletion" do
    it "is blocked while the client still has route stops" do
      client = create(:client)
      create(:route_stop, client: client, route: create(:route, zone: client.zone))

      expect(client.destroy).to be_falsey
      expect(client.errors[:base]).to be_present
      expect(Client.exists?(client.id)).to be(true)
    end
  end

  describe ".filter_by" do
    let(:zone) { create(:zone) }

    def names(relation)
      relation.order(:name).pluck(:name)
    end

    it "matches clients whose name contains the text" do
      create(:client, name: "Tienda La 42", zone: zone)
      create(:client, name: "Salsamentaria El Paisa", zone: zone)

      expect(names(Client.filter_by(name: "tienda"))).to eq(["Tienda La 42"])
    end

    it "ignores case and accents in both directions" do
      create(:client, name: "Tienda San José", zone: zone)
      create(:client, name: "Autoservicio Dona Rosa", zone: zone)

      expect(names(Client.filter_by(name: "JOSE"))).to eq(["Tienda San José"])
      expect(names(Client.filter_by(name: "doña"))).to eq(["Autoservicio Dona Rosa"])
    end

    it "matches % and _ literally instead of as wildcards" do
      create(:client, name: "Tienda 100%", zone: zone)
      create(:client, name: "Tienda 1000", zone: zone)
      create(:client, name: "Tienda A_B", zone: zone)
      create(:client, name: "Tienda AXB", zone: zone)

      expect(names(Client.filter_by(name: "100%"))).to eq(["Tienda 100%"])
      expect(names(Client.filter_by(name: "a_b"))).to eq(["Tienda A_B"])
    end

    it "lists only the clients of the given zone" do
      create(:client, name: "Propio", zone: zone)
      create(:client, name: "Ajeno", zone: create(:zone))

      expect(names(Client.filter_by(zone_id: zone.id))).to eq(["Propio"])
    end

    it "lists only the stops of the given route, once each" do
      route = create(:route, zone: zone)
      other_route = create(:route, zone: zone)
      stop = create(:client, name: "Parada", zone: zone)
      create(:client, name: "Sin Ruta", zone: zone)
      create(:route_stop, route: route, client: stop)
      create(:route_stop, route: other_route, client: stop)

      expect(names(Client.filter_by(route_id: route.id))).to eq(["Parada"])
    end

    it "combines filters" do
      create(:client, name: "Tienda Norte", zone: zone)
      create(:client, name: "Tienda Sur", zone: zone)
      create(:client, name: "Tienda Centro", zone: create(:zone))
      create(:client, name: "Salsamentaria", zone: zone)

      expect(names(Client.filter_by(name: "tienda", zone_id: zone.id))).to eq(["Tienda Norte", "Tienda Sur"])
    end

    it "ignores blank values" do
      create(:client, name: "Uno", zone: zone)
      create(:client, name: "Dos", zone: create(:zone))

      expect(Client.filter_by(name: "", zone_id: nil, route_id: "").count).to eq(2)
    end
  end
end
