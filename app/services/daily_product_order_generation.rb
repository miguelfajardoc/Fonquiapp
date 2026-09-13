class DailyProductOrderGeneration
  def initialize(zone:, day: Date.current)
    @zone = zone
    @day = day
  end

  def call
    totals = compute_totals

    DailyProductOrder.transaction do
      DailyProductOrder.where(zone: @zone, day: @day).delete_all
      totals.each do |(client_id, product_id), quantity|
        next unless quantity.positive?

        DailyProductOrder.create!(zone: @zone, client_id: client_id, product_id: product_id,
                                  quantity: quantity, day: @day)
      end
    end
  end

  private

  def compute_totals
    totals = Hash.new(0)

    DefaultProductQuantity.where(zone: @zone).find_each do |default_quantity|
      totals[[default_quantity.client_id, default_quantity.product_id]] += default_quantity.quantity
    end

    PendingProduct.where(zone: @zone, state: :pending).find_each do |pending_product|
      totals[[pending_product.client_id, pending_product.product_id]] += pending_product.quantity
    end

    totals
  end
end
