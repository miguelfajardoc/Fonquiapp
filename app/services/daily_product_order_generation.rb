class DailyProductOrderGeneration
  def initialize(route:, day: Date.current)
    @route = route
    @zone = route.zone
    @day = day
  end

  # Copies the route's defaults into the day's batch; defaults are unique per product and always positive.
  def call
    DailyProductOrder.transaction do
      DailyProductOrder.where(route: @route, day: @day).delete_all
      @route.default_product_quantities.find_each do |default_quantity|
        DailyProductOrder.create!(zone: @zone, route: @route, product_id: default_quantity.product_id,
                                  quantity: default_quantity.quantity, day: @day)
      end
    end
  end
end
