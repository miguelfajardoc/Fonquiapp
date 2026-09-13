require "rails_helper"

RSpec.describe DailyProductOrderGeneration do
  describe "#call" do
    it "combines a client+product's default quantity and pending quantity" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 3, state: :pending)

      described_class.new(zone: zone).call

      order = DailyProductOrder.find_by(zone: zone, client: client, product: product)
      expect(order.quantity).to eq(8)
      expect(order.day).to eq(Date.current)
    end

    it "does not count delivered or canceled pending products" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 3, state: :delivered)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 2, state: :canceled)

      described_class.new(zone: zone).call

      order = DailyProductOrder.find_by(zone: zone, client: client, product: product)
      expect(order.quantity).to eq(5)
    end

    it "creates no record for a client+product with nothing due" do
      zone = create(:zone)
      create(:client, zone: zone)
      create(:product)

      expect { described_class.new(zone: zone).call }.not_to change(DailyProductOrder, :count)
    end

    it "does not include clients or pending products from another zone" do
      zone = create(:zone)
      other_zone = create(:zone)
      other_client = create(:client, zone: other_zone)
      product = create(:product)
      create(:default_product_quantity, zone: other_zone, client: other_client, product: product, quantity: 4)

      described_class.new(zone: zone).call

      expect(DailyProductOrder.where(client: other_client)).to be_empty
    end

    it "replaces the existing batch when the same zone is regenerated the same day" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)
      default_quantity = create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)

      described_class.new(zone: zone).call
      expect(DailyProductOrder.find_by(zone: zone, client: client, product: product).quantity).to eq(5)

      default_quantity.update!(quantity: 9)
      described_class.new(zone: zone).call

      orders = DailyProductOrder.where(zone: zone, client: client, product: product)
      expect(orders.count).to eq(1)
      expect(orders.first.quantity).to eq(9)
    end

    it "leaves a different day's batch for the same zone untouched" do
      zone = create(:zone)
      previous_day_order = create(:daily_product_order, zone: zone, day: Date.current - 1)

      described_class.new(zone: zone, day: Date.current).call

      expect(DailyProductOrder.exists?(previous_day_order.id)).to be(true)
    end
  end
end
