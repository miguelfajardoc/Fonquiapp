class ZonesController < ApplicationController
  NEW_ZONE_MODAL_FRAME = "new_zone_modal_form".freeze

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

    return create_from_new_zone_modal if turbo_frame_request_id == NEW_ZONE_MODAL_FRAME

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

  def create_from_new_zone_modal
    return render_new_zone_modal_errors unless @zone.save

    option = helpers.tag.option(@zone.name, value: @zone.id, selected: true)
    render turbo_stream: turbo_stream.append("client_zone_select") { option }
  end

  def render_new_zone_modal_errors
    render turbo_stream: turbo_stream.replace(
      NEW_ZONE_MODAL_FRAME, partial: "zones/form", locals: { zone: @zone, in_dialog: true }
    ), status: :unprocessable_content
  end

  def set_zone
    @zone = Zone.find(params.expect(:id))
  end

  def zone_params
    params.expect(zone: [:name])
  end
end
