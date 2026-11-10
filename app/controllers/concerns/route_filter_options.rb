# Route choices for an index filter bar: every route until a zone is chosen, then only that zone's routes.
# Ordered by zone then name, so routes sharing a name stay next to the rest of their zone.
module RouteFilterOptions
  extend ActiveSupport::Concern

  private

  def route_filter_options(zone_id)
    routes = Route.joins(:zone).order("zones.name", :name)
    zone_id.present? ? routes.where(zone_id: zone_id) : routes
  end
end
