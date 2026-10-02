class PendingProductsController < ApplicationController
  FILTER_KEYS = %i[zone_id client_name state].freeze
  # With no state chosen the list shows what still needs handling; "all" disables the state filter.
  DEFAULT_STATE = "pending".freeze

  before_action :set_pending_product, only: %i[edit update destroy toggle_state]

  def index
    @zones = Zone.order(:name)
    @filters = params.slice(*FILTER_KEYS).permit(*FILTER_KEYS).to_h
    @filters[:state] = DEFAULT_STATE if @filters[:state].blank?
    @sort = params[:sort] == "oldest" ? "oldest" : "newest"
    direction = @sort == "oldest" ? :asc : :desc
    scope = PendingProduct.includes(:client, :product, :zone).filter_by(@filters)
                          .order(created_at: direction, id: direction)
    @pagy, @pending_products = pagy(:offset, scope)
  end

  def new
    @pending_product = PendingProduct.new(client_id: params[:client_id])
    load_client_panel
  end

  def edit
    render layout: false
  end

  def create
    @pending_product = PendingProduct.new(pending_product_params)
    @selected_client = @pending_product.client
    @pending_product.zone_id = @selected_client&.zone_id
    @pending_product.state = :pending

    if @pending_product.save
      render turbo_stream: created_turbo_stream
    else
      render turbo_stream: form_turbo_stream(@pending_product), status: :unprocessable_content
    end
  end

  def update
    if @pending_product.update(pending_product_params)
      render turbo_stream: turbo_stream.replace(helpers.dom_id(@pending_product),
                                                partial: row_partial,
                                                locals: { pending_product: @pending_product })
    else
      render :edit, layout: false, status: :unprocessable_content
    end
  end

  def destroy
    @pending_product.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(helpers.dom_id(@pending_product)) }
      format.html { redirect_to pending_products_path, notice: t("pending_products.flash.deleted") }
    end
  end

  def toggle_state
    @pending_product.update!(state: @pending_product.pending? ? :delivered : :pending)
    render turbo_stream: turbo_stream.replace(helpers.dom_id(@pending_product),
                                              partial: row_partial,
                                              locals: { pending_product: @pending_product })
  end

  def client_options
    clients = Client.order(:name)
    clients = clients.where("clients.name ILIKE ?", "%#{params[:q]}%") if params[:q].present?

    render turbo_stream: helpers.hw_async_combobox_options(clients)
  end

  private

  def set_pending_product
    @pending_product = PendingProduct.find(params.expect(:id))
  end

  def pending_product_params
    params.expect(pending_product: %i[client_id product_id quantity])
  end

  def load_client_panel
    @selected_client = Client.find_by(id: params[:client_id])
    @client_pending_products = if @selected_client
                                 PendingProduct.where(client: @selected_client).order(created_at: :desc)
                               else
                                 PendingProduct.none
                               end
  end

  def row_partial
    params[:context] == "panel" ? "pending_products/panel_item" : "pending_products/row"
  end

  def form_turbo_stream(pending_product)
    turbo_stream.replace("pending_product_form", partial: "pending_products/form",
                                                 locals: { pending_product: pending_product })
  end

  def created_turbo_stream
    client_pending_products = PendingProduct.where(client: @selected_client).order(created_at: :desc)

    [
      turbo_stream.replace(helpers.dom_id(@selected_client, :pending_products),
                           partial: "pending_products/client_pending_list",
                           locals: { client: @selected_client, pending_products: client_pending_products }),
      form_turbo_stream(PendingProduct.new(client_id: @selected_client.id))
    ]
  end
end
