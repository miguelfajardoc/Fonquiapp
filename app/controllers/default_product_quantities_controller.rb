class DefaultProductQuantitiesController < ApplicationController
  FILTER_KEYS = %i[client_name zone_id].freeze

  before_action :set_default_product_quantity, only: %i[edit update destroy]

  def index
    @zones = Zone.order(:name)
    @filters = params.slice(*FILTER_KEYS).permit(*FILTER_KEYS).to_h
    scope = DefaultProductQuantity.includes(:client, :product, :zone).filter_by(@filters)
                                  .order("clients.name", "products.name")
    @pagy, @default_product_quantities = pagy(:offset, scope)
  end

  def new
    @default_product_quantity = DefaultProductQuantity.new(zone_id: params[:zone_id])
    @selected_client = Client.find_by(id: params[:client_id])
    @client_defaults = client_defaults_for(@selected_client)
  end

  def edit
    render layout: false
  end

  def create
    @default_product_quantity = DefaultProductQuantity.new(default_product_quantity_params)

    if @default_product_quantity.save
      render turbo_stream: created_turbo_stream
    else
      render turbo_stream: form_turbo_stream(@default_product_quantity), status: :unprocessable_content
    end
  end

  # Zone and client are fixed once a default exists; the edit modal only changes product and quantity.
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

  def client_options
    clients = Client.where(zone_id: params[:zone_id]).order(:name)
    clients = clients.where("clients.name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

    render turbo_stream: helpers.hw_async_combobox_options(clients)
  end

  private

  def set_default_product_quantity
    @default_product_quantity = DefaultProductQuantity.find(params.expect(:id))
  end

  def default_product_quantity_params
    params.expect(default_product_quantity: %i[zone_id client_id product_id quantity])
  end

  def client_defaults_for(client)
    return DefaultProductQuantity.none unless client

    DefaultProductQuantity.where(client: client).includes(:product).order("products.name").references(:product)
  end

  def row_partial
    params[:context] == "panel" ? "default_product_quantities/panel_item" : "default_product_quantities/row"
  end

  # Refreshes the client's list and resets the form for the next entry, keeping zone and client.
  def created_turbo_stream
    client = @default_product_quantity.client
    [
      turbo_stream.replace(helpers.dom_id(client, :default_product_quantities),
                           partial: "default_product_quantities/client_default_list",
                           locals: { client: client, default_product_quantities: client_defaults_for(client) }),
      form_turbo_stream(DefaultProductQuantity.new(zone_id: @default_product_quantity.zone_id, client_id: client.id))
    ]
  end

  def form_turbo_stream(default_product_quantity)
    turbo_stream.replace("default_product_quantity_form",
                         partial: "default_product_quantities/form",
                         locals: { default_product_quantity: default_product_quantity })
  end
end
