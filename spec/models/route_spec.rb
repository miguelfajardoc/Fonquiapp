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
      client_a = create(:client)
      client_b = create(:client)
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
  end
end
