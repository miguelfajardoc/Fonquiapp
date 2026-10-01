require "rails_helper"

RSpec.describe "Routes", type: :request do
  describe "GET /routes" do
    it "lists every existing route with its zone, name, clients, and per-row actions" do
      zone = create(:zone, name: "Bosa")
      route = create(:route, zone: zone, name: "Ruta 1")
      client_a = create(:client, zone: zone, name: "Tienda A")
      client_b = create(:client, zone: zone, name: "Tienda B")
      create(:route_stop, route: route, client: client_b)
      create(:route_stop, route: route, client: client_a)
      RouteStop.find_by(route: route, client: client_a).insert_at(1)

      get routes_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(zone.name)
      expect(response.body).to include(route.name)
      expect(response.body).to include("Tienda A, Tienda B")
      expect(response.body).to include("Crear ruta")
      expect(response.body).to include(edit_route_path(route))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog regardless of route count" do
      create_list(:route, 3)

      get routes_path

      expect(response.body.scan("<dialog").count).to eq(1)
      expect(response.body).to include("¿Estás seguro")
    end

    it "truncates a long client list with an ellipsis-capable cell and keeps the full list in a title attribute" do
      zone = create(:zone)
      route = create(:route, zone: zone)
      clients = create_list(:client, 4, zone: zone)
      clients.each { |client| create(:route_stop, route: route, client: client) }

      get routes_path

      cell = response.parsed_body.at_css("td.truncate")
      expect(cell["title"]).to eq(clients.map(&:name).join(", "))
    end
  end

  describe "GET /routes/new" do
    it "renders the form with a Crear submit button" do
      get new_route_path

      expect(response).to have_http_status(:ok)
      route_form = response.parsed_body.at_css("form[action='#{routes_path}']")
      expect(route_form.at_css("input[type=submit]")["value"]).to eq("Crear")
    end
  end

  describe "GET /routes/:id/edit" do
    it "renders the form with an Actualizar submit button and pre-fills existing stops in order" do
      zone = create(:zone)
      route = create(:route, zone: zone)
      client_a = create(:client, zone: zone, name: "Tienda A")
      client_b = create(:client, zone: zone, name: "Tienda B")
      create(:route_stop, route: route, client: client_a)
      create(:route_stop, route: route, client: client_b)

      get edit_route_path(route)

      expect(response).to have_http_status(:ok)
      route_form = response.parsed_body.at_css("form[action='#{route_path(route)}']")
      expect(route_form.at_css("input[type=submit]")["value"]).to eq("Actualizar")

      list = response.parsed_body.at_css("[data-route-stops-target='list']")
      selected = list.css("select[name='route[route_stops_attributes][][client_id]']").map do |select|
        select.at_css("option[selected]")&.attr("value")
      end
      expect(selected).to eq([client_a.id.to_s, client_b.id.to_s])
    end
  end

  describe "GET /routes/client_options" do
    it "returns only clients belonging to the requested zone" do
      zone_a = create(:zone)
      zone_b = create(:zone)
      client_in_a = create(:client, zone: zone_a, name: "Tienda A")
      client_in_b = create(:client, zone: zone_b, name: "Tienda B")

      get client_options_routes_path(zone_id: zone_a.id)

      expect(response.body).to include(client_in_a.name)
      expect(response.body).not_to include(client_in_b.name)
    end
  end

  describe "POST /routes" do
    it "creates a route with an ordered set of client stops" do
      zone = create(:zone)
      client_a = create(:client, zone: zone)
      client_b = create(:client, zone: zone)

      expect do
        post routes_path, params: {
          route: {
            name: "Ruta 1", zone_id: zone.id,
            route_stops_attributes: [
              { client_id: client_b.id, position: 1 },
              { client_id: client_a.id, position: 2 }
            ]
          }
        }
      end.to change(Route, :count).by(1).and change(RouteStop, :count).by(2)

      expect(response).to redirect_to(routes_path)
      route = Route.find_by(name: "Ruta 1")
      expect(route.clients).to eq([client_b, client_a])
    end

    it "allows a route with no stops" do
      zone = create(:zone)

      expect do
        post routes_path, params: { route: { name: "Ruta 1", zone_id: zone.id } }
      end.to change(Route, :count).by(1)

      expect(response).to redirect_to(routes_path)
    end

    it "re-renders the form with a blank name" do
      zone = create(:zone)

      expect do
        post routes_path, params: { route: { name: "", zone_id: zone.id } }
      end.not_to change(Route, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with no zone selected" do
      expect do
        post routes_path, params: { route: { name: "Ruta 1", zone_id: "" } }
      end.not_to change(Route, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with a name already taken in the same zone" do
      zone = create(:zone)
      create(:route, zone: zone, name: "Ruta 1")

      expect do
        post routes_path, params: { route: { name: "Ruta 1", zone_id: zone.id } }
      end.not_to change(Route, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "does not create anything when a stop's client belongs to a different zone" do
      zone = create(:zone)
      other_zone_client = create(:client)

      expect do
        post routes_path, params: {
          route: {
            name: "Ruta 1", zone_id: zone.id,
            route_stops_attributes: [{ client_id: other_zone_client.id, position: 1 }]
          }
        }
      end.not_to change(Route, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /routes/:id" do
    it "updates the route's name together with added, removed, and reordered stops" do
      zone = create(:zone)
      route = create(:route, zone: zone, name: "Ruta 1")
      client_a = create(:client, zone: zone)
      client_b = create(:client, zone: zone)
      client_c = create(:client, zone: zone)
      stop_a = create(:route_stop, route: route, client: client_a)
      stop_b = create(:route_stop, route: route, client: client_b)

      patch route_path(route), params: {
        route: {
          name: "Ruta 1 renombrada",
          route_stops_attributes: [
            { id: stop_a.id, client_id: client_a.id, position: 2 },
            { id: stop_b.id, client_id: client_b.id, _destroy: "1" },
            { client_id: client_c.id, position: 1 }
          ]
        }
      }

      expect(response).to redirect_to(routes_path)
      route.reload
      expect(route.name).to eq("Ruta 1 renombrada")
      expect(route.clients).to eq([client_c, client_a])
    end

    it "removes a stop marked for destruction" do
      zone = create(:zone)
      route = create(:route, zone: zone)
      stop = create(:route_stop, route: route)

      expect do
        patch route_path(route), params: {
          route: { route_stops_attributes: [{ id: stop.id, client_id: stop.client_id, _destroy: "1" }] }
        }
      end.to change(RouteStop, :count).by(-1)

      expect(response).to redirect_to(routes_path)
    end

    it "does not change the route when the submission is invalid" do
      route = create(:route, name: "Ruta 1")

      patch route_path(route), params: { route: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(route.reload.name).to eq("Ruta 1")
    end
  end

  describe "DELETE /routes/:id" do
    it "deletes the route and its stops" do
      route = create(:route)
      create_list(:route_stop, 2, route: route)

      expect do
        delete route_path(route)
      end.to change(Route, :count).by(-1).and change(RouteStop, :count).by(-2)

      expect(response).to redirect_to(routes_path)
      expect(flash[:notice]).to be_present
    end
  end
end
