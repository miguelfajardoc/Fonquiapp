require "rails_helper"

RSpec.describe DailyProductOrderGeneration do
  describe "#call" do
    let(:zone) { create(:zone) }
    let(:route) { create(:route, zone: zone) }
    let(:product) { create(:product) }

    def stop_client(on_route = route)
      create(:client, zone: on_route.zone).tap { |client| create(:route_stop, route: on_route, client: client) }
    end

    it "combines a stop client+product's default quantity and pending quantity, stamped with the route" do
      client = stop_client
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 3, state: :pending)

      described_class.new(route: route).call

      order = DailyProductOrder.find_by(route: route, client: client, product: product)
      expect(order.quantity).to eq(8)
      expect(order.day).to eq(Date.current)
      expect(order.zone).to eq(zone)
    end

    it "does not count delivered or canceled pending products" do
      client = stop_client
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 3, state: :delivered)
      create(:pending_product, zone: zone, client: client, product: product, quantity: 2, state: :canceled)

      described_class.new(route: route).call

      expect(DailyProductOrder.find_by(route: route, client: client, product: product).quantity).to eq(5)
    end

    it "creates no record for a stop client+product with nothing due" do
      stop_client
      product

      expect { described_class.new(route: route).call }.not_to change(DailyProductOrder, :count)
    end

    it "does not include zone clients that are not stops of the route" do
      off_route_client = create(:client, zone: zone)
      create(:default_product_quantity, zone: zone, client: off_route_client, product: product, quantity: 5)
      create(:pending_product, zone: zone, client: off_route_client, product: product, quantity: 2, state: :pending)

      described_class.new(route: route).call

      expect(DailyProductOrder.where(client: off_route_client)).to be_empty
    end

    it "does not include clients from another zone" do
      other_zone = create(:zone)
      other_client = create(:client, zone: other_zone)
      create(:default_product_quantity, zone: other_zone, client: other_client, product: product, quantity: 4)

      described_class.new(route: route).call

      expect(DailyProductOrder.where(client: other_client)).to be_empty
    end

    it "includes a client that is a stop of two routes in each route's batch" do
      other_route = create(:route, zone: zone)
      client = stop_client
      create(:route_stop, route: other_route, client: client)
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)

      described_class.new(route: route).call
      described_class.new(route: other_route).call

      expect(DailyProductOrder.find_by(route: route, client: client, product: product).quantity).to eq(5)
      expect(DailyProductOrder.find_by(route: other_route, client: client, product: product).quantity).to eq(5)
    end

    it "replaces the existing batch when the same route is regenerated the same day" do
      client = stop_client
      default_quantity = create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 5)

      described_class.new(route: route).call
      expect(DailyProductOrder.find_by(route: route, client: client, product: product).quantity).to eq(5)

      default_quantity.update!(quantity: 9)
      described_class.new(route: route).call

      orders = DailyProductOrder.where(route: route, client: client, product: product)
      expect(orders.count).to eq(1)
      expect(orders.first.quantity).to eq(9)
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
