class DefaultProductQuantitiesController < ApplicationController
  before_action :set_default_product_quantity, only: %i[edit update destroy]

  def index
    @default_product_quantities = DefaultProductQuantity
                                  .includes(:client, :product)
                                  .order("clients.name", "products.name")
  end

  def new
    @default_product_quantity = DefaultProductQuantity.new(zone_id: params[:zone_id])
  end

  def edit
    @default_product_quantity.assign_attributes(zone_id: params[:zone_id], client_id: nil) if params[:zone_id].present?
  end

  def create
    @default_product_quantity = DefaultProductQuantity.new(default_product_quantity_params)

    if @default_product_quantity.save
      redirect_to default_product_quantities_path, notice: t("default_product_quantities.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @default_product_quantity.update(default_product_quantity_params)
      redirect_to default_product_quantities_path, notice: t("default_product_quantities.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @default_product_quantity.destroy
    redirect_to default_product_quantities_path, notice: t("default_product_quantities.flash.deleted")
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
end
