class DailyProductOrderGeneration
  def initialize(route:, day: Date.current)
    @route = route
    @zone = route.zone
    @day = day
  end

  def call
    totals = compute_totals

    DailyProductOrder.transaction do
      DailyProductOrder.where(route: @route, day: @day).delete_all
      totals.each do |(client_id, product_id), quantity|
        next unless quantity.positive?

        DailyProductOrder.create!(zone: @zone, route: @route, client_id: client_id, product_id: product_id,
                                  quantity: quantity, day: @day)
      end
    end
  end

  private

  def compute_totals
    totals = Hash.new(0)
    client_ids = @route.route_stops.pluck(:client_id)

    DefaultProductQuantity.where(zone: @zone, client_id: client_ids).find_each do |default_quantity|
      totals[[default_quantity.client_id, default_quantity.product_id]] += default_quantity.quantity
    end

    PendingProduct.where(zone: @zone, client_id: client_ids, state: :pending).find_each do |pending_product|
      totals[[pending_product.client_id, pending_product.product_id]] += pending_product.quantity
    end

    totals
  end
end
