require "rails_helper"

RSpec.describe DailyProductOrder, type: :model do
  describe "creation" do
    it "is valid with the four references, a quantity and a day" do
      expect(build(:daily_product_order)).to be_valid
    end

    it "stores day as a calendar date" do
      order = create(:daily_product_order, day: Date.new(2026, 9, 10))
      expect(order.reload.day).to eq(Date.new(2026, 9, 10))
      expect(order.day).to be_a(Date)
    end
  end

  describe "validations" do
    it "is invalid without a day" do
      order = build(:daily_product_order, day: nil)
      expect(order).not_to be_valid
      expect(order.errors[:day]).to be_present
    end

    it "is invalid with a non-positive or non-integer quantity" do
      [0, -2, 1.5].each do |value|
        order = build(:daily_product_order, quantity: value)
        expect(order).not_to be_valid
        expect(order.errors[:quantity]).to be_present
      end
    end

    it "is invalid without a product, client or zone" do
      order = DailyProductOrder.new(quantity: 1, day: Date.current)
      expect(order).not_to be_valid
      expect(order.errors[:product]).to be_present
      expect(order.errors[:client]).to be_present
      expect(order.errors[:zone]).to be_present
    end

    it "is invalid without a route" do
      order = build(:daily_product_order, route: nil)
      expect(order).not_to be_valid
      expect(order.errors[:route]).to be_present
    end
  end

  describe "referential integrity" do
    it "cannot be created with a route that does not exist" do
      order = build(:daily_product_order)
      order.route_id = 0
      expect { order.save(validate: false) }.to raise_error(ActiveRecord::InvalidForeignKey)
    end

    it "allows repeated orders for the same product+client+zone on the same day" do
      first = create(:daily_product_order, day: Date.new(2026, 9, 10))
      second = build(:daily_product_order,
                     product: first.product, client: first.client, zone: first.zone, day: Date.new(2026, 9, 10))

      expect(second).to be_valid
    end

    it "blocks deleting a product it references" do
      order = create(:daily_product_order)
      product = order.product

      expect(product.destroy).to be_falsey
      expect(product.errors[:base]).to be_present
      expect(Product.exists?(product.id)).to be(true)
    end
  end
end
