require "rails_helper"

RSpec.describe Zone, type: :model do
  describe "validations" do
    it "is valid with a name" do
      expect(build(:zone, name: "Norte")).to be_valid
    end

    it "is invalid without a name" do
      zone = build(:zone, name: "")
      expect(zone).not_to be_valid
      expect(zone.errors[:name]).to be_present
    end

    it "is invalid when the name is already taken" do
      create(:zone, name: "Norte")
      duplicate = build(:zone, name: "Norte")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include("has already been taken")
    end
  end

  describe "#clients" do
    it "returns only the clients that reference the zone" do
      zone = create(:zone)
      other_zone = create(:zone)
      mine = create_list(:client, 2, zone: zone)
      create(:client, zone: other_zone)

      expect(zone.clients).to match_array(mine)
    end
  end

  describe "deletion" do
    it "is blocked while the zone still has clients" do
      zone = create(:zone)
      create(:client, zone: zone)

      expect(zone.destroy).to be_falsey
      expect(zone.errors[:base]).to be_present
      expect(Zone.exists?(zone.id)).to be(true)
      expect(zone.clients.count).to eq(1)
    end

    it "succeeds when the zone has no clients" do
      zone = create(:zone)

      expect { zone.destroy }.to change(Zone, :count).by(-1)
    end

    it "is blocked while the zone still has routes" do
      zone = create(:zone)
      create(:route, zone: zone)

      expect(zone.destroy).to be_falsey
      expect(zone.errors[:base]).to be_present
      expect(Zone.exists?(zone.id)).to be(true)
    end
  end
end
