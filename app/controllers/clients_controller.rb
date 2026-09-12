class ClientsController < ApplicationController
  before_action :set_client, only: %i[show edit update destroy]

  def index
    @clients = Client.includes(:zone).order(:name)
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

  def set_client
    @client = Client.find(params.expect(:id))
  end

  def client_params
    params.expect(client: %i[name address url phone zone_id])
  end
end
