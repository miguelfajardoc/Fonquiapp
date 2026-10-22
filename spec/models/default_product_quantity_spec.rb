require "rails_helper"

RSpec.describe DefaultProductQuantity, type: :model do
  describe "creation" do
    it "is valid with a route, a product and a quantity" do
      expect(build(:default_product_quantity)).to be_valid
    end

    it "reads its zone from the route" do
      record = build(:default_product_quantity)
      expect(record.zone).to eq(record.route.zone)
    end
  end

  describe "validations" do
    it "is invalid with a zero, negative or non-integer quantity" do
      [0, -1, 2.5].each do |value|
        record = build(:default_product_quantity, quantity: value)
        expect(record).not_to be_valid
        expect(record.errors[:quantity]).to be_present
      end
    end

    it "is invalid without a route or product" do
      record = DefaultProductQuantity.new(quantity: 1)
      expect(record).not_to be_valid
      expect(record.errors[:route]).to be_present
      expect(record.errors[:product]).to be_present
    end
  end

  describe "one default per route+product" do
    it "rejects a second row for the same combination" do
      existing = create(:default_product_quantity)
      duplicate = build(:default_product_quantity, route: existing.route, product: existing.product)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to include("has already been taken")
    end

    it "allows a combination that differs in route or in product" do
      existing = create(:default_product_quantity)

      expect(build(:default_product_quantity, route: existing.route)).to be_valid
      expect(build(:default_product_quantity, product: existing.product)).to be_valid
    end
  end

  describe "referential integrity" do
    it "blocks deleting a product it references" do
      product = create(:default_product_quantity).product

      expect(product.destroy).to be_falsey
      expect(product.errors[:base]).to be_present
      expect(Product.exists?(product.id)).to be(true)
    end
  end

  describe ".filter_by" do
    let(:zone) { create(:zone) }
    let(:route) { create(:route, zone: zone) }
    let(:same_zone_route) { create(:route, zone: zone) }

    it "filters by the route's zone and by route" do
      wanted = create(:default_product_quantity, route: route)
      same_zone = create(:default_product_quantity, route: same_zone_route)
      create(:default_product_quantity)

      expect(DefaultProductQuantity.filter_by(zone_id: zone.id)).to contain_exactly(wanted, same_zone)
      expect(DefaultProductQuantity.filter_by(zone_id: zone.id, route_id: route.id)).to eq([wanted])
    end

    it "ignores blank values" do
      create_list(:default_product_quantity, 2)

      expect(DefaultProductQuantity.filter_by(zone_id: "", route_id: "").count).to eq(2)
    end
  end
end
