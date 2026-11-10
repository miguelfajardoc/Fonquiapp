class RoutesController < ApplicationController
  include RouteFilterOptions

  # What the client combobox reads to show the chosen client's name after a full page load.
  ClientFilter = Struct.new(:client_id, :client)

  before_action :set_route, only: %i[edit update destroy]

  def index
    @zones = Zone.order(:name)
    load_filters
    scope = Route.joins(:zone).preload(:zone, route_stops: :client).filter_by(@filters).order("zones.name", :name)
    @pagy, @routes = pagy(:offset, scope)
  end

  def new
    @route = Route.new
  end

  def edit; end

  def create
    @route = Route.new(route_params)

    if RouteStop.acts_as_list_no_update { @route.save }
      redirect_to routes_path, notice: t("routes.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if RouteStop.acts_as_list_no_update { @route.update(route_params) }
      redirect_to routes_path, notice: t("routes.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @route.destroy
      redirect_to routes_path, notice: t("routes.flash.deleted")
    else
      redirect_to routes_path, alert: t("routes.flash.delete_blocked")
    end
  end

  def client_options
    clients = Client.where(zone_id: params[:zone_id]).order(:name)

    render partial: "routes/client_options", locals: { clients: clients }, layout: false
  end

  private

  # A route only applies within the selected zone (if any), so a stale route from another zone is ignored.
  def load_filters
    @filter_zone_id = params[:zone_id].presence
    @filter_routes = route_filter_options(@filter_zone_id)
    @filter_route_id = params[:route_id].presence if @filter_routes.exists?(id: params[:route_id])
    @filters = { zone_id: @filter_zone_id, route_id: @filter_route_id, client_id: params[:client_id].presence }
    @client_filter = client_filter(@filters[:client_id])
  end

  # An unknown client id still filters, matching no route, and leaves the combobox empty.
  def client_filter(client_id)
    client = Client.find_by(id: client_id) if client_id
    ClientFilter.new(client&.id, client)
  end

  def set_route
    @route = Route.find(params.expect(:id))
  end

  def route_params
    params.expect(route: [:name, :zone_id, { route_stops_attributes: [%i[id client_id position _destroy]] }])
  end
end
