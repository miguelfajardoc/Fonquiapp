class ClientsController < ApplicationController
  FILTER_KEYS = %i[name zone_id route_id].freeze

  before_action :set_client, only: %i[show edit update destroy]

  def index
    @zones = Zone.order(:name)
    @routes = params[:zone_id].present? ? Route.where(zone_id: params[:zone_id]).order(:name) : Route.none
    @filters = filter_params
    @pagy, @clients = pagy(:offset, Client.includes(:zone, :routes).filter_by(@filters).order(:name))
  end

  def show; end

  def new
    @client = Client.new
  end

  def edit; end

  def create
    @client = Client.new(client_params)

    if @client.save
      redirect_to clients_path, notice: t("clients.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @client.update(client_params)
      redirect_to clients_path, notice: t("clients.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @client.destroy
      redirect_to clients_path, notice: t("clients.flash.deleted")
    else
      redirect_to clients_path, alert: @client.errors.full_messages.to_sentence
    end
  end

  private

  # A route only applies within the selected zone, so a stale or hand-edited
  # route_id falls back to filtering by zone alone.
  def filter_params
    filters = params.slice(*FILTER_KEYS).permit(*FILTER_KEYS).to_h
    filters.delete(:route_id) unless @routes.exists?(id: filters[:route_id])
    filters
  end

  def set_client
    @client = Client.find(params.expect(:id))
  end

  def client_params
    params.expect(client: %i[name address url phone zone_id])
  end
end
