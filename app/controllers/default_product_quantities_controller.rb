class DefaultProductQuantitiesController < ApplicationController
  before_action :set_default_product_quantity, only: %i[edit update destroy]

  def index
    @zones = Zone.order(:name)
    load_filters
    scope = DefaultProductQuantity.includes(:product, route: :zone).filter_by(@filters)
                                  .order("zones.name", "routes.name", "products.name")
    @pagy, @default_product_quantities = pagy(:offset, scope)
  end

  def new
    @zone_id = params[:zone_id].presence
    @default_product_quantity = DefaultProductQuantity.new
    @selected_route = Route.find_by(id: params[:route_id])
    @route_defaults = route_defaults_for(@selected_route)
  end

  def edit
    render layout: false
  end

  def create
    @default_product_quantity = DefaultProductQuantity.new(default_product_quantity_params)

    if @default_product_quantity.save
      render turbo_stream: created_turbo_stream
    else
      render turbo_stream: form_turbo_stream(@default_product_quantity, params[:zone_id]),
             status: :unprocessable_content
    end
  end

  # Zone and route are fixed once a default exists; the edit modal only changes product and quantity.
  def update
    if @default_product_quantity.update(params.expect(default_product_quantity: %i[product_id quantity]))
      render turbo_stream: turbo_stream.replace(helpers.dom_id(@default_product_quantity),
                                                partial: row_partial,
                                                locals: { default_product_quantity: @default_product_quantity })
    else
      render :edit, layout: false, status: :unprocessable_content
    end
  end

  def destroy
    @default_product_quantity.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(helpers.dom_id(@default_product_quantity)) }
      format.html { redirect_to default_product_quantities_path, notice: t("default_product_quantities.flash.deleted") }
    end
  end

  private

  def set_default_product_quantity
    @default_product_quantity = DefaultProductQuantity.find(params.expect(:id))
  end

  # The zone select only narrows the route choices; the zone itself comes from the route.
  def default_product_quantity_params
    params.expect(default_product_quantity: %i[route_id product_id quantity])
  end

  # A route only applies within the selected zone, so a stale route from another zone is ignored.
  def load_filters
    @filter_zone_id = params[:zone_id].presence
    @filter_routes = @filter_zone_id ? Route.where(zone_id: @filter_zone_id).order(:name) : Route.none
    @filter_route_id = params[:route_id].presence if @filter_routes.exists?(id: params[:route_id])
    @filters = { zone_id: @filter_zone_id, route_id: @filter_route_id }
  end

  def route_defaults_for(route)
    return DefaultProductQuantity.none unless route

    route.default_product_quantities.includes(:product).order("products.name").references(:product)
  end

  def row_partial
    params[:context] == "panel" ? "default_product_quantities/panel_item" : "default_product_quantities/row"
  end

  # Refreshes the route's list and resets the form for the next entry, keeping zone and route.
  def created_turbo_stream
    route = @default_product_quantity.route
    [
      turbo_stream.replace(helpers.dom_id(route, :default_product_quantities),
                           partial: "default_product_quantities/route_default_list",
                           locals: { route: route, default_product_quantities: route_defaults_for(route) }),
      form_turbo_stream(DefaultProductQuantity.new(route: route), route.zone_id)
    ]
  end

  def form_turbo_stream(default_product_quantity, zone_id)
    turbo_stream.replace("default_product_quantity_form",
                         partial: "default_product_quantities/form",
                         locals: { default_product_quantity: default_product_quantity, zone_id: zone_id })
  end
end
