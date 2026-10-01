class RoutesController < ApplicationController
  before_action :set_route, only: %i[edit update destroy]

  def index
    @routes = Route.joins(:zone).preload(:zone, route_stops: :client).order("zones.name", :name)
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
    @route.destroy
    redirect_to routes_path, notice: t("routes.flash.deleted")
  end

  def client_options
    clients = Client.where(zone_id: params[:zone_id]).order(:name)

    render partial: "routes/client_options", locals: { clients: clients }, layout: false
  end

  private

  def set_route
    @route = Route.find(params.expect(:id))
  end

  def route_params
    params.expect(route: [:name, :zone_id, route_stops_attributes: [[:id, :client_id, :position, :_destroy]]])
  end
end
