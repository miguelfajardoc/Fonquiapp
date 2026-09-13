class DailyProductOrdersController < ApplicationController
  XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def index
    @zones = Zone.order(:name)
    @batches = load_batches
  end

  def generate
    zone = Zone.find_by(id: params[:zone_id])

    if zone.nil?
      redirect_to daily_product_orders_path, alert: t(".missing_zone")
    else
      DailyProductOrderGeneration.new(zone: zone).call
      redirect_to daily_product_orders_path, notice: t(".generated", zone: zone.name)
    end
  end

  def consolidated
    zone = Zone.find(params.expect(:zone_id))
    day = Date.parse(params.expect(:day))
    package = DailyProductOrderConsolidation.new(zone: zone, day: day).call

    send_data package.to_stream.read,
              filename: "consolidado_#{zone.name.parameterize}_#{day.iso8601}.xlsx",
              type: XLSX_MIME_TYPE
  end

  private

  def load_batches
    zones_by_id = @zones.index_by(&:id)
    batches = DailyProductOrder.select(:day, :zone_id).distinct.filter_map do |batch|
      zone = zones_by_id[batch.zone_id]
      { day: batch.day, zone: zone } if zone
    end
    batches.sort_by { |batch| [-batch[:day].jd, batch[:zone].name] }
  end
end
