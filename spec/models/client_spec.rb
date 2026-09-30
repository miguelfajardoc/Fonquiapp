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
    it "persists without address, url or phone" do
      client = build(:client, address: nil, url: nil, phone: nil)

      expect(client.save).to be(true)
      client.reload
      expect(client.address).to be_nil
      expect(client.url).to be_nil
      expect(client.phone).to be_nil
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
      create(:route_stop, client: client)

      expect(client.destroy).to be_falsey
      expect(client.errors[:base]).to be_present
      expect(Client.exists?(client.id)).to be(true)
    end
  end
end
