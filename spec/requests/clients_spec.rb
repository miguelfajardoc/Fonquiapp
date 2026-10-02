require "rails_helper"

RSpec.describe "Clients", type: :request do
  describe "GET /clients" do
    it "lists every existing client with its fields, a create control, and a delete control" do
      zone = create(:zone, name: "Norte")
      client = create(:client, name: "Acme", address: "Calle 1", url: "https://acme.test",
                               phone: "555-0100", zone: zone)

      get clients_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(client.address)
      expect(response.body).to include(client.url)
      expect(response.body).to include(client.phone)
      expect(response.body).to include(zone.name)
      expect(response.body).to include("Crear cliente")
      expect(response.body).to include(client_path(client))
      expect(response.body).to include("Eliminar")
    end
  end

  describe "GET /clients with filters and pagination" do
    def listed_names
      response.parsed_body.css("turbo-frame#clients tbody tr").reject { |row| row.at_css("td[colspan]") }
              .map { |row| row.css("td").first.text.strip }
    end

    def route_options
      response.parsed_body.css("turbo-frame#client_route_filter option").map { |o| o.text.strip }
    end

    let(:zone) { create(:zone, name: "Bosa") }

    it "renders the filter form, the client list frame, and the route filter frame" do
      get clients_path

      body = response.parsed_body
      form = body.at_css("form[method='get'][data-turbo-frame='clients']")
      expect(form).not_to be_nil
      expect(form.at_css("input[name='name']")).not_to be_nil
      expect(form.at_css("select[name='zone_id']")).not_to be_nil
      expect(form.at_css("turbo-frame#client_route_filter select[name='route_id']")).not_to be_nil
      expect(body.at_css("turbo-frame#clients[data-turbo-action='advance']")).not_to be_nil
    end

    it "has no in-page title and puts the create button and the clear link on the filters' row" do
      get clients_path(name: "x", zone_id: zone.id)

      body = response.parsed_body
      expect(body.at_css("main h1, h1")).to be_nil
      form = body.at_css("form[data-turbo-frame='clients']")
      row = form.parent
      expect(row.css("> a").map { |a| a.text.strip }).to include("Crear cliente")
      clear = form.css("a").find { |a| a.text.strip == "Limpiar filtros" }
      expect(clear["href"]).to eq(clients_path)
      expect(clear["data-turbo-frame"]).to eq("_top")
    end

    it "filters by a name fragment, ignoring case and accents" do
      create(:client, name: "Tienda San José", zone: zone)
      create(:client, name: "Salsamentaria El Paisa", zone: zone)

      get clients_path(name: "jose")

      expect(listed_names).to eq(["Tienda San José"])
    end

    it "filters by zone" do
      create(:client, name: "Propio", zone: zone)
      create(:client, name: "Ajeno", zone: create(:zone))

      get clients_path(zone_id: zone.id)

      expect(listed_names).to eq(["Propio"])
    end

    it "filters by zone and route, listing only the route's stops" do
      route = create(:route, zone: zone)
      stop = create(:client, name: "Parada", zone: zone)
      create(:client, name: "Sin Ruta", zone: zone)
      create(:route_stop, route: route, client: stop)

      get clients_path(zone_id: zone.id, route_id: route.id)

      expect(listed_names).to eq(["Parada"])
    end

    it "ignores a route that does not belong to the selected zone" do
      other_route = create(:route)
      create(:route_stop, route: other_route)
      create(:client, name: "Propio", zone: zone)

      get clients_path(zone_id: zone.id, route_id: other_route.id)

      expect(listed_names).to eq(["Propio"])
    end

    it "offers only the selected zone's routes, and none without a zone" do
      create(:route, zone: zone, name: "Ruta Propia")
      create(:route, name: "Ruta Ajena")

      get clients_path
      expect(route_options).to eq(["Todas las rutas"])

      get clients_path(zone_id: zone.id)
      expect(route_options).to eq(["Todas las rutas", "Ruta Propia"])
    end

    it "pre-fills the filter controls from the params" do
      route = create(:route, zone: zone)

      get clients_path(name: "tienda", zone_id: zone.id, route_id: route.id)

      body = response.parsed_body
      expect(body.at_css("input[name='name']")["value"]).to eq("tienda")
      expect(body.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(zone.id.to_s)
      expect(body.at_css("select[name='route_id'] option[selected]")["value"]).to eq(route.id.to_s)
    end

    it "shows every route a client is a stop of in the column after the zone" do
      on_routes = create(:client, name: "En Rutas", zone: zone)
      create(:client, name: "Sin Rutas", zone: zone)
      create(:route_stop, route: create(:route, zone: zone, name: "Ruta 2"), client: on_routes)
      create(:route_stop, route: create(:route, zone: zone, name: "Ruta 1"), client: on_routes)

      get clients_path

      headers = response.parsed_body.css("turbo-frame#clients thead th").map { |th| th.text.strip }
      expect(headers[headers.index("Zona") + 1]).to eq("Ruta")
      cells = response.parsed_body.css("turbo-frame#clients tbody tr").to_h do |row|
        tds = row.css("td").map { |td| td.text.strip }
        [tds[0], tds[headers.index("Ruta")]]
      end
      expect(cells["En Rutas"]).to eq("Ruta 1, Ruta 2")
      expect(cells["Sin Rutas"]).to eq("")
    end

    it "gives each client row an Editar link to its edit page, outside the row click and the table frame" do
      client = create(:client, name: "Tienda Norte", zone: zone)

      get clients_path(zone_id: zone.id)

      skip_cell = response.parsed_body.at_css("turbo-frame#clients tbody tr td[data-row-target='skip']")
      link = skip_cell.css("a").find { |a| a.text.strip == "Editar" }
      expect(link["href"]).to eq(edit_client_path(client))
      expect(link["data-turbo-frame"]).to eq("_top")
      expect(skip_cell.text).to include("Eliminar")
    end

    it "shows a message when no client matches" do
      create(:client, name: "Tienda", zone: zone)

      get clients_path(name: "zzz")

      expect(listed_names).to be_empty
      expect(response.parsed_body.at_css("turbo-frame#clients").text).to include(I18n.t("clients.index.no_results"))
    end

    context "with more clients than fit on one page" do
      before do
        25.times { |n| create(:client, name: format("Bosa %02d", n), zone: zone) }
        5.times { |n| create(:client, name: format("Otra %02d", n), zone: create(:zone)) }
      end

      it "shows the first 20 clients in name order with pagination controls" do
        get clients_path

        expect(listed_names.size).to eq(20)
        expect(listed_names.first).to eq("Bosa 00")
        expect(response.parsed_body.at_css("turbo-frame#clients nav.pagy")).not_to be_nil
      end

      it "keeps the active filters on the page links and shows the rest on the next page" do
        get clients_path(zone_id: zone.id)

        next_link = response.parsed_body.at_css("turbo-frame#clients nav.pagy a[rel='next']")
        query = Rack::Utils.parse_query(URI.parse(next_link["href"]).query)
        expect(query).to include("zone_id" => zone.id.to_s, "page" => "2")

        get clients_path(zone_id: zone.id, page: 2)

        expect(listed_names).to eq((20..24).map { |n| format("Bosa %02d", n) })
      end
    end

    it "shows no pagination controls when every client fits on one page" do
      3.times { |n| create(:client, name: "Cliente #{n}", zone: zone) }

      get clients_path

      expect(listed_names.size).to eq(3)
      expect(response.parsed_body.at_css("nav.pagy")).to be_nil
    end
  end

  describe "GET /clients/:id" do
    it "shows every field and an edit and delete control" do
      zone = create(:zone, name: "Norte")
      client = create(:client, name: "Acme", address: "Calle 1", url: "https://acme.test",
                               phone: "555-0100", zone: zone)

      get client_path(client)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(client.address)
      expect(response.body).to include(client.url)
      expect(response.body).to include(client.phone)
      expect(response.body).to include(zone.name)
      expect(response.body).to include(edit_client_path(client))
      expect(response.body).to include("Eliminar")
    end
  end

  describe "GET /clients/new" do
    it "renders the form with a Crear submit button" do
      get new_client_path

      expect(response).to have_http_status(:ok)
      client_form = response.parsed_body.at_css("form[action='#{clients_path}']")
      expect(client_form.at_css("input[type=submit]")["value"]).to eq("Crear")
    end

    it "offers creating a zone as an option inside the zone select itself" do
      zone = create(:zone, name: "Norte")

      get new_client_path

      zone_select = response.parsed_body.at_css("#client_zone_select")
      expect(zone_select.at_css("option[value='#{zone.id}']").text).to eq("Norte")
      expect(zone_select.at_css("option[value='new']").text).to eq("+ Crear zona")
    end
  end

  describe "GET /clients/:id/edit" do
    it "renders the form with an Actualizar submit button" do
      client = create(:client)

      get edit_client_path(client)

      expect(response).to have_http_status(:ok)
      client_form = response.parsed_body.at_css("form[action='#{client_path(client)}']")
      expect(client_form.at_css("input[type=submit]")["value"]).to eq("Actualizar")
    end
  end

  describe "POST /clients" do
    it "creates a client with a name and a zone" do
      zone = create(:zone)

      expect do
        post clients_path, params: { client: { name: "Acme", zone_id: zone.id } }
      end.to change(Client, :count).by(1)

      expect(response).to redirect_to(clients_path)
    end

    it "re-renders the form with a blank name" do
      zone = create(:zone)

      expect do
        post clients_path, params: { client: { name: "", zone_id: zone.id } }
      end.not_to change(Client, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with no zone selected" do
      expect do
        post clients_path, params: { client: { name: "Acme", zone_id: "" } }
      end.not_to change(Client, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /clients/:id" do
    it "updates a client with valid data" do
      client = create(:client, name: "Acme")
      zone = create(:zone)

      patch client_path(client), params: { client: { name: "Acme Corp", zone_id: zone.id } }

      expect(response).to redirect_to(clients_path)
      expect(client.reload.name).to eq("Acme Corp")
    end

    it "does not update a client with a blank name" do
      client = create(:client, name: "Acme")

      patch client_path(client), params: { client: { name: "" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(client.reload.name).to eq("Acme")
    end

    it "does not update a client with no zone selected" do
      client = create(:client, name: "Acme")

      patch client_path(client), params: { client: { zone_id: "" } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /clients/:id" do
    it "deletes a client with no associated records" do
      client = create(:client)

      expect do
        delete client_path(client)
      end.to change(Client, :count).by(-1)

      expect(response).to redirect_to(clients_path)
      expect(flash[:notice]).to be_present
    end

    it "does not delete a client still referenced by an ordering record, and reports why" do
      client = create(:client)
      create(:daily_product_order, client: client)

      expect do
        delete client_path(client)
      end.not_to change(Client, :count)

      expect(response).to redirect_to(clients_path)
      expect(flash[:alert]).to be_present
      expect(Client.exists?(client.id)).to be(true)
    end
  end
end
