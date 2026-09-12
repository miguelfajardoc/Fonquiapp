class ZonesController < ApplicationController
  before_action :set_zone, only: %i[edit update destroy]

  def index
    @zones = Zone.order(:name)
  end

  def new
    @zone = Zone.new
  end

  def edit; end

  def create
    @zone = Zone.new(zone_params)

    if @zone.save
      redirect_to zones_path, notice: t("zones.flash.created")
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @zone.update(zone_params)
      redirect_to zones_path, notice: t("zones.flash.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @zone.destroy
      redirect_to zones_path, notice: t("zones.flash.deleted")
    else
      redirect_to zones_path, alert: @zone.errors.full_messages.to_sentence
    end
  end

  private

  def set_zone
    @zone = Zone.find(params.expect(:id))
  end

  def zone_params
    params.expect(zone: [:name])
  end
end
