# Creates clients from a CSV with the columns name, address, url, phone, zone and route. Zones and routes are
# found by name (ignoring case and accents) or created, and the client becomes the route's last stop. The
# location comes only from the url; a link without readable coordinates just leaves the client unlocated.
class ClientCsvImport < CsvImport
  REQUIRED_HEADERS = %w[name address zone].freeze

  private

  # One transaction per row, so a failing client never leaves behind the zone or route created for it.
  def import_row(row)
    require_values!(row, "name", "address", "zone")
    latitude, longitude = GoogleMaps.coordinates_from_url(value(row, "url"))

    Client.transaction do
      zone = find_or_create_zone!(value(row, "zone"))
      route = find_or_create_route!(zone, value(row, "route")) if value(row, "route")
      client = Client.create!(name: value(row, "name"), address: value(row, "address"), phone: value(row, "phone"),
                              zone: zone, latitude: latitude, longitude: longitude)
      route&.route_stops&.create!(client: client)
    end
    :created
  end

  def find_or_create_zone!(name)
    named(Zone.all, "zones.name", name).first || Zone.create!(name: name)
  end

  def find_or_create_route!(zone, name)
    named(zone.routes, "routes.name", name).first || zone.routes.create!(name: name)
  end
end
