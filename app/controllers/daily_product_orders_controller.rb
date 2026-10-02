class DailyProductOrdersController < ApplicationController
  XLSX_MIME_TYPE = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".freeze

  def index
    @zones = Zone.order(:name)
    @selected_zone_id = params[:zone_id].presence
    @routes = @selected_zone_id ? Route.where(zone_id: @selected_zone_id).order(:name) : Route.none
    load_table_filters
    @pagy, @batches = pagy(:offset, batches_scope.filter_by(@table_filters))
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

  # Table filters use their own params (filter_zone_id/filter_route_id) so they never clash with the
  # generation form's zone_id/route_id on the same URL. A route only applies within the filter zone.
  def load_table_filters
    @filter_zone_id = params[:filter_zone_id].presence
    @filter_routes = @filter_zone_id ? Route.where(zone_id: @filter_zone_id).order(:name) : Route.none
    @filter_route_id = params[:filter_route_id].presence if @filter_routes.exists?(id: params[:filter_route_id])
    @table_filters = { zone_id: @filter_zone_id, route_id: @filter_route_id }
  end

  # Most recently (re)generated batch first; route_id and day keep pages stable on ties.
  def batches_scope
    DailyProductOrder
      .joins(:zone, :route)
      .group(:day, :zone_id, :route_id, "zones.name", "routes.name")
      .select(:day, :zone_id, :route_id, "zones.name AS zone_name", "routes.name AS route_name")
      .order(Arel.sql("MAX(daily_product_orders.created_at) DESC"))
      .order(route_id: :desc, day: :desc)
  end
end
