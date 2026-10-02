require "rails_helper"

RSpec.describe DefaultProductQuantity, type: :model do
  describe "creation" do
    it "is valid with the three references and a quantity" do
      expect(build(:default_product_quantity)).to be_valid
    end

    it "allows a quantity of zero" do
      expect(build(:default_product_quantity, quantity: 0)).to be_valid
    end
  end

  describe "validations" do
    it "is invalid with a negative or non-integer quantity" do
      [-1, 2.5].each do |value|
        record = build(:default_product_quantity, quantity: value)
        expect(record).not_to be_valid
        expect(record.errors[:quantity]).to be_present
      end
    end

    it "is invalid without a product, client or zone" do
      record = DefaultProductQuantity.new(quantity: 1)
      expect(record).not_to be_valid
      expect(record.errors[:product]).to be_present
      expect(record.errors[:client]).to be_present
      expect(record.errors[:zone]).to be_present
    end
  end

  describe "one default per product+client+zone" do
    it "rejects a second row for the same combination" do
      existing = create(:default_product_quantity)
      duplicate = build(:default_product_quantity,
                        product: existing.product, client: existing.client, zone: existing.zone)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to include("has already been taken")
    end

    it "allows a combination that differs in any one reference" do
      existing = create(:default_product_quantity)
      other = build(:default_product_quantity,
                    product: existing.product, client: existing.client, zone: create(:zone))

      expect(other).to be_valid
    end
  end

  describe "referential integrity" do
    it "blocks deleting a client it references" do
      default_quantity = create(:default_product_quantity)
      client = default_quantity.client

      expect(client.destroy).to be_falsey
      expect(client.errors[:base]).to be_present
      expect(Client.exists?(client.id)).to be(true)
    end
  end

  describe ".filter_by" do
    let(:zone) { create(:zone) }
    let(:other_zone) { create(:zone) }

    def client_names(relation)
      relation.joins(:client).order("clients.name").pluck("clients.name")
    end

    it "matches the client name ignoring case and accents" do
      create(:default_product_quantity, zone: zone, client: create(:client, name: "Tienda San José", zone: zone))
      create(:default_product_quantity, zone: zone, client: create(:client, name: "El Paisa", zone: zone))

      expect(client_names(DefaultProductQuantity.filter_by(client_name: "jose"))).to eq(["Tienda San José"])
    end

    it "filters by zone and combines with the client name" do
      create(:default_product_quantity, zone: zone, client: create(:client, name: "Tienda Norte", zone: zone))
      create(:default_product_quantity, zone: zone, client: create(:client, name: "Salsamentaria", zone: zone))
      create(:default_product_quantity, zone: other_zone,
                                        client: create(:client, name: "Tienda Centro", zone: other_zone))

      expect(client_names(DefaultProductQuantity.filter_by(zone_id: zone.id)))
        .to eq(["Salsamentaria", "Tienda Norte"])
      expect(client_names(DefaultProductQuantity.filter_by(client_name: "tienda", zone_id: zone.id)))
        .to eq(["Tienda Norte"])
    end

    it "ignores blank values" do
      create_list(:default_product_quantity, 2)

      expect(DefaultProductQuantity.filter_by(client_name: "", zone_id: "").count).to eq(2)
    end
  end
end
