require "rails_helper"

RSpec.describe Route, type: :model do
  describe "validations" do
    it "is valid with a name and a zone" do
      expect(build(:route, name: "Ruta 1", zone: create(:zone))).to be_valid
    end

    it "is invalid without a name" do
      route = build(:route, name: "")
      expect(route).not_to be_valid
      expect(route.errors[:name]).to be_present
    end

    it "is invalid when the name is already taken in the same zone" do
      zone = create(:zone)
      create(:route, zone: zone, name: "Ruta 1")
      duplicate = build(:route, zone: zone, name: "Ruta 1")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end

    it "allows the same name in a different zone" do
      create(:route, name: "Ruta 1")
      other = build(:route, name: "Ruta 1", zone: create(:zone))

      expect(other).to be_valid
    end

    it "is invalid without a zone" do
      route = build(:route, zone: nil)
      expect(route).not_to be_valid
      expect(route.errors[:zone]).to be_present
    end
  end

  describe "referential integrity" do
    it "cannot be created with a zone that does not exist" do
      route = build(:route)
      route.zone_id = 0
      expect { route.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "#zone" do
    it "reports the zone it belongs to" do
      zone = create(:zone)
      expect(create(:route, zone: zone).zone).to eq(zone)
    end
  end

  describe "#clients" do
    it "lists the clients reachable through its route stops, in stop order" do
      route = create(:route)
      client_a = create(:client, zone: route.zone)
      client_b = create(:client, zone: route.zone)
      create(:route_stop, route: route, client: client_b)
      create(:route_stop, route: route, client: client_a)
      RouteStop.find_by(route: route, client: client_a).insert_at(1)

      expect(route.clients).to eq([client_a, client_b])
    end
  end

  describe "deletion" do
    it "deletes its route stops along with it" do
      route = create(:route)
      create_list(:route_stop, 2, route: route)

      expect { route.destroy }.to change(RouteStop, :count).by(-2)
      expect(Route.exists?(route.id)).to be(false)
    end

    it "deletes its default product quantities along with it, keeping the products" do
      route = create(:route)
      defaults = create_list(:default_product_quantity, 2, route: route)

      expect { route.destroy }.to change(DefaultProductQuantity, :count).by(-2)
      expect(Product.where(id: defaults.map(&:product_id)).count).to eq(2)
    end

    it "cannot be deleted while a daily product order references it, keeping its stops and defaults" do
      route = create(:route)
      create_list(:route_stop, 2, route: route)
      create_list(:default_product_quantity, 2, route: route)
      create(:daily_product_order, route: route, zone: route.zone)

      expect(route.destroy).to be_falsey
      expect(route.errors[:base]).to be_present
      expect(Route.exists?(route.id)).to be(true)
      expect(RouteStop.where(route: route).count).to eq(2)
      expect(DefaultProductQuantity.where(route: route).count).to eq(2)
    end
  end

  describe ".filter_by" do
    let(:bosa) { create(:zone, name: "Bosa") }
    let(:soacha) { create(:zone, name: "Soacha") }
    let(:client) { create(:client, zone: bosa) }
    let!(:ruta1) { create(:route, zone: bosa, name: "Ruta 1") }
    let!(:ruta2) { create(:route, zone: bosa, name: "Ruta 2") }
    let!(:ruta3) { create(:route, zone: soacha, name: "Ruta 3") }

    it "filters by zone" do
      expect(described_class.filter_by(zone_id: bosa.id)).to contain_exactly(ruta1, ruta2)
    end

    it "filters by route" do
      expect(described_class.filter_by(route_id: ruta3.id)).to eq([ruta3])
    end

    it "filters by a client who is a stop, listing each route once" do
      create(:route_stop, route: ruta1, client: client)
      create(:route_stop, route: ruta2, client: client)
      create(:route_stop, route: ruta2, client: create(:client, zone: bosa))

      expect(described_class.filter_by(client_id: client.id).to_a).to contain_exactly(ruta1, ruta2)
      expect(described_class.filter_by(client_id: client.id).count).to eq(2)
    end

    it "combines zone and client" do
      other_zone_client = create(:client, zone: soacha)
      create(:route_stop, route: ruta3, client: other_zone_client)

      expect(described_class.filter_by(zone_id: bosa.id, client_id: other_zone_client.id)).to be_empty
    end

    it "does not restrict the list for blank values" do
      expect(described_class.filter_by(zone_id: "", route_id: nil, client_id: ""))
        .to contain_exactly(ruta1, ruta2, ruta3)
    end
  end
end
