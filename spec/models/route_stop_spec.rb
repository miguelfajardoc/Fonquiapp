require "rails_helper"

RSpec.describe RouteStop, type: :model do
  describe "creation" do
    it "is valid with a route and a client" do
      expect(build(:route_stop)).to be_valid
    end

    it "is assigned a position" do
      expect(create(:route_stop).position).to eq(1)
    end
  end

  describe "validations" do
    it "is invalid without a route" do
      stop = build(:route_stop, route: nil)
      expect(stop).not_to be_valid
      expect(stop.errors[:route]).to be_present
    end

    it "is invalid without a client" do
      stop = build(:route_stop, client: nil)
      expect(stop).not_to be_valid
      expect(stop.errors[:client]).to be_present
    end
  end

  describe "referential integrity" do
    it "cannot be created with a route that does not exist" do
      stop = build(:route_stop)
      stop.route_id = 0
      expect { stop.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "cannot be created with a client that does not exist" do
      stop = build(:route_stop)
      stop.client_id = 0
      expect { stop.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end
  end

  describe "one stop per client per route" do
    it "rejects a second stop for the same route and client" do
      existing = create(:route_stop)
      duplicate = build(:route_stop, route: existing.route, client: existing.client)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:client_id]).to include("has already been taken")
    end

    it "allows the same client on a different route" do
      existing = create(:route_stop)
      other = build(:route_stop, route: create(:route), client: existing.client)

      expect(other).to be_valid
    end

    it "allows a different client on the same route" do
      existing = create(:route_stop)
      other = build(:route_stop, route: existing.route, client: create(:client))

      expect(other).to be_valid
    end
  end

  describe "position ordering" do
    it "appends new stops after the existing ones" do
      route = create(:route)
      first = create(:route_stop, route: route)
      second = create(:route_stop, route: route)
      third = create(:route_stop, route: route)

      expect([first.reload.position, second.reload.position, third.reload.position]).to eq([1, 2, 3])
    end

    it "closes the gap when a stop is removed" do
      route = create(:route)
      first = create(:route_stop, route: route)
      second = create(:route_stop, route: route)
      third = create(:route_stop, route: route)

      second.destroy

      expect(first.reload.position).to eq(1)
      expect(third.reload.position).to eq(2)
    end

    it "shifts only its own route's stops when a stop is moved" do
      route = create(:route)
      first = create(:route_stop, route: route)
      second = create(:route_stop, route: route)
      third = create(:route_stop, route: route)
      other_route_stop = create(:route_stop)

      third.insert_at(1)

      expect(third.reload.position).to eq(1)
      expect(first.reload.position).to eq(2)
      expect(second.reload.position).to eq(3)
      expect(other_route_stop.reload.position).to eq(1)
    end

    it "keeps position sequences independent between routes" do
      route_a = create(:route)
      route_b = create(:route)
      create(:route_stop, route: route_a)
      stop_b = create(:route_stop, route: route_b)

      create(:route_stop, route: route_a)

      expect(stop_b.reload.position).to eq(1)
    end
  end
end
