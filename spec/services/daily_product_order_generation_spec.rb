require "rails_helper"

RSpec.describe DailyProductOrderGeneration do
  describe "#call" do
    let(:zone) { create(:zone) }
    let(:route) { create(:route, zone: zone) }
    let(:product) { create(:product) }

    def quantities(on_route = route)
      DailyProductOrder.where(route: on_route).joins(:product).pluck("products.name", :quantity).to_h
    end

    it "creates one order per route default with its quantity, stamped with the day, route and zone" do
      create(:default_product_quantity, route: route, product: create(:product, name: "Queso"), quantity: 20)
      create(:default_product_quantity, route: route, product: create(:product, name: "Crema"), quantity: 5)

      described_class.new(route: route).call

      expect(quantities).to eq("Queso" => 20, "Crema" => 5)
      expect(DailyProductOrder.where(route: route).pluck(:day, :zone_id).uniq).to eq([[Date.current, zone.id]])
    end

    it "does not count pending products" do
      client = create(:client, zone: zone)
      create(:route_stop, route: route, client: client)
      create(:default_product_quantity, route: route, product: product, quantity: 20)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 3, state: :pending)

      described_class.new(route: route).call

      expect(DailyProductOrder.find_by(route: route, product: product).quantity).to eq(20)
    end

    it "creates no record for a product the route has no default for" do
      create(:default_product_quantity, route: route, product: product, quantity: 20)
      other_product = create(:product)

      described_class.new(route: route).call

      expect(DailyProductOrder.where(route: route, product: other_product)).to be_empty
    end

    it "does not include other routes' defaults" do
      other_route = create(:route, zone: zone)
      create(:default_product_quantity, route: route, product: product, quantity: 20)
      create(:default_product_quantity, route: other_route, product: product, quantity: 7)

      described_class.new(route: route).call

      expect(DailyProductOrder.where(route: route).pluck(:quantity)).to eq([20])
    end

    it "creates an empty batch for a route with no defaults" do
      expect { described_class.new(route: route).call }.not_to change(DailyProductOrder, :count)
    end

    it "replaces the existing batch when the same route is regenerated the same day" do
      default_quantity = create(:default_product_quantity, route: route, product: product, quantity: 5)

      described_class.new(route: route).call
      default_quantity.update!(quantity: 9)
      described_class.new(route: route).call

      expect(DailyProductOrder.where(route: route, product: product).pluck(:quantity)).to eq([9])
    end

    it "drops a product whose default was deleted when regenerating the same day" do
      default_quantity = create(:default_product_quantity, route: route, product: product, quantity: 5)

      described_class.new(route: route).call
      default_quantity.destroy!
      described_class.new(route: route).call

      expect(DailyProductOrder.where(route: route, product: product)).to be_empty
    end

    it "leaves a different day's batch for the same route untouched" do
      previous_day_order = create(:daily_product_order, route: route, zone: zone, day: Date.current - 1)

      described_class.new(route: route, day: Date.current).call

      expect(DailyProductOrder.exists?(previous_day_order.id)).to be(true)
    end

    it "leaves another route of the same zone untouched when regenerating" do
      other_route = create(:route, zone: zone)
      other_order = create(:daily_product_order, route: other_route, zone: zone, day: Date.current)

      described_class.new(route: route).call

      expect(DailyProductOrder.exists?(other_order.id)).to be(true)
    end
  end
end
