class DailyProductOrdersController < ApplicationController
  XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def index
    @zones = Zone.order(:name)
    @selected_zone_id = params[:zone_id].presence
    @routes = @selected_zone_id ? Route.where(zone_id: @selected_zone_id).order(:name) : Route.none
    @pagy, @batches = pagy(:offset, batches_scope)
  end

  def generate
    return redirect_to(daily_product_orders_path, alert: t(".missing_zone")) if params[:zone_id].blank?

    route = route_in_selected_zone
    return redirect_to(daily_product_orders_path, alert: t(".missing_route")) if route.nil?

    DailyProductOrderGeneration.new(route: route).call
    redirect_to daily_product_orders_path, notice: generated_notice(route)
  end

  def consolidated
    route = Route.find(params.expect(:route_id))
    day = Date.parse(params.expect(:day))
    package = DailyProductOrderConsolidation.new(route: route, day: day).call

    send_data package.to_stream.read, filename: consolidated_filename(route, day), type: XLSX_MIME_TYPE
  end

  private

  def route_in_selected_zone
    Route.find_by(id: params[:route_id], zone_id: params[:zone_id])
  end

  def generated_notice(route)
    t("daily_product_orders.generate.generated", zone: route.zone.name, route: route.name)
  end

  def consolidated_filename(route, day)
    "consolidado_#{route.zone.name.parameterize}_#{route.name.parameterize}_#{day.iso8601}.xlsx"
  end

  def batches_scope
    DailyProductOrder
      .joins(:zone, :route)
      .group(:day, :zone_id, :route_id, "zones.name", "routes.name")
      .select(:day, :zone_id, :route_id, "zones.name AS zone_name", "routes.name AS route_name")
      .order(day: :desc)
      .order("zones.name ASC, routes.name ASC")
  end
end
