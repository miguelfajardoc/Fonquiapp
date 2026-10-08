module ClientsHelper
  # Stimulus wiring for the client form's map; empty when no Google Maps key is
  # configured, so the form then works as a plain form.
  def location_picker_data(client)
    return {} unless GoogleMaps.api_key

    {
      controller: "location-picker",
      location_picker_api_key_value: GoogleMaps.api_key,
      location_picker_map_id_value: GoogleMaps.map_id,
      location_picker_auto_locate_value: client.address.present? && !client.located?,
      location_picker_messages_value: location_picker_messages.to_json
    }
  end

  private

  def location_picker_messages
    {
      notFound: t("clients.form.location.not_found"),
      relocate: t("clients.form.location.relocate"),
      reverseNotFound: t("clients.form.location.reverse_not_found"),
      loadError: t("clients.form.location.load_error")
    }
  end
end
