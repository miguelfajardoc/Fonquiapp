require "rails_helper"

RSpec.describe "DefaultProductQuantities", type: :request do
  describe "GET /default_product_quantities" do
    it "lists every existing record with zone, route, product, quantity, and per-row edit/delete controls" do
      zone = create(:zone, name: "Bosa")
      route = create(:route, zone: zone, name: "Ruta 1")
      product = create(:product, name: "Agua 500ml")
      record = create(:default_product_quantity, route: route, product: product, quantity: 7)

      get default_product_quantities_path

      expect(response).to have_http_status(:ok)
      expect(frame_headers("default_product_quantities")).to eq(%w[Zona Ruta Producto Cantidad Acciones])
      expect(frame_rows("default_product_quantities").map { |row| row.css("td").first(4).map { |td| td.text.strip } })
        .to eq([["Bosa", "Ruta 1", "Agua 500ml", "7"]])
      expect(response.body).to include("Crear default")
      expect(response.body).to include(edit_default_product_quantity_path(record))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog and one edit modal regardless of record count" do
      create_list(:default_product_quantity, 3)

      get default_product_quantities_path

      expect(response.body.scan("<dialog").count).to eq(2)
      expect(response.body).to include("¿Estás seguro")
      expect(response.parsed_body.at_css("dialog turbo-frame#default_product_quantity_edit_modal")).not_to be_nil
    end

    it "orders records by zone, route, then product" do
      bosa = create(:zone, name: "Bosa")
      ruta1 = create(:route, zone: bosa, name: "Ruta 1")
      ruta2 = create(:route, zone: bosa, name: "Ruta 2")
      soacha_route = create(:route, zone: create(:zone, name: "Soacha"), name: "Ruta 0")
      create(:default_product_quantity, route: soacha_route, product: create(:product, name: "Arequipe"))
      create(:default_product_quantity, route: ruta2, product: create(:product, name: "Queso"))
      create(:default_product_quantity, route: ruta1, product: Product.find_by(name: "Queso"))
      create(:default_product_quantity, route: ruta1, product: create(:product, name: "Crema"))

      get default_product_quantities_path

      listed = frame_rows("default_product_quantities").map { |row| row.css("td").first(3).map { |td| td.text.strip } }
      expect(listed).to eq([["Bosa", "Ruta 1", "Crema"], ["Bosa", "Ruta 1", "Queso"], ["Bosa", "Ruta 2", "Queso"],
                            ["Soacha", "Ruta 0", "Arequipe"]])
    end
  end

  describe "GET /default_product_quantities with filters and pagination" do
    let(:zone) { create(:zone, name: "Bosa") }
    let(:other_zone) { create(:zone, name: "Soacha") }
    let(:route) { create(:route, zone: zone, name: "Ruta 1") }

    it "has no in-page title and puts the zone and route filters, clear link, and create button on one row" do
      get default_product_quantities_path

      body = response.parsed_body
      expect(body.at_css("h1")).to be_nil
      form = body.at_css("form[method='get'][data-turbo-frame='default_product_quantities']")
      expect(form.at_css("input[name='client_name']")).to be_nil
      zone_select = form.at_css("select[name='zone_id']")
      expect(zone_select["data-action"]).to include("client-zone-filter#reload", "auto-submit#submit")
      expect(zone_select["data-auto-submit-clear-param"]).to eq("route_id")
      expect(form.at_css("turbo-frame#default_route_filter select[name='route_id']")).not_to be_nil
      expect(form.parent.css("> a").map { |a| a.text.strip }).to include("Crear default")
      expect(clear_filters_link["href"]).to eq(default_product_quantities_path)
      expect(clear_filters_link["data-turbo-frame"]).to eq("_top")
    end

    it "offers only the selected zone's routes, and none without a zone" do
      route
      create(:route, zone: zone, name: "Ruta 2")
      create(:route, zone: other_zone, name: "Ruta 3")

      get default_product_quantities_path(zone_id: zone.id)
      options = response.parsed_body.css("select[name='route_id'] option").map { |o| o.text.strip }
      expect(options).to eq(["Todas las rutas", "Ruta 1", "Ruta 2"])

      get default_product_quantities_path
      expect(response.parsed_body.css("select[name='route_id'] option").size).to eq(1)
    end

    it "filters by zone and by route, ignoring a route outside the zone" do
      same_zone_route = create(:route, zone: zone, name: "Ruta 2")
      other_route = create(:route, zone: other_zone, name: "Ruta 3")
      create(:default_product_quantity, route: route)
      create(:default_product_quantity, route: same_zone_route)
      create(:default_product_quantity, route: other_route)

      get default_product_quantities_path(zone_id: zone.id)
      expect(frame_column("default_product_quantities", 1)).to eq(["Ruta 1", "Ruta 2"])

      get default_product_quantities_path(zone_id: zone.id, route_id: route.id)
      expect(frame_column("default_product_quantities", 1)).to eq(["Ruta 1"])
      body = response.parsed_body
      expect(body.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(zone.id.to_s)
      expect(body.at_css("select[name='route_id'] option[selected]")["value"]).to eq(route.id.to_s)

      get default_product_quantities_path(zone_id: zone.id, route_id: other_route.id)
      expect(frame_column("default_product_quantities", 1)).to eq(["Ruta 1", "Ruta 2"])
    end

    it "renders each row with its dom id and an Editar button that opens the edit modal" do
      record = create(:default_product_quantity, route: route)

      get default_product_quantities_path(zone_id: zone.id)

      frame = response.parsed_body.at_css("turbo-frame#default_product_quantities")
      row = frame.at_css("tr#default_product_quantity_#{record.id}")
      button = row.css("button").find { |b| b.text.strip == "Editar" }
      expect(button["data-action"]).to eq("edit-modal#open")
      expect(button["data-edit-modal-url-param"]).to eq(edit_default_product_quantity_path(record, context: "table"))
      expect(response.parsed_body.at_css("[data-controller~='edit-modal']")).not_to be_nil
    end

    it "shows a message when no record matches" do
      create(:default_product_quantity, route: route)

      get default_product_quantities_path(zone_id: other_zone.id)

      expect(frame_rows("default_product_quantities")).to be_empty
      expect(response.body).to include(I18n.t("default_product_quantities.index.no_results"))
    end

    it "paginates 20 per page, keeping the zone filter on page links" do
      products = Array.new(25) { |n| create(:product, name: format("Producto %02d", n)) }
      products.each { |product| create(:default_product_quantity, route: route, product: product) }
      create_list(:default_product_quantity, 5, route: create(:route, zone: other_zone))

      get default_product_quantities_path(zone_id: zone.id)

      expect(frame_rows("default_product_quantities").size).to eq(20)
      expect(next_page_query("default_product_quantities")).to include("zone_id" => zone.id.to_s, "page" => "2")

      get default_product_quantities_path(zone_id: zone.id, page: 2)

      expect(frame_column("default_product_quantities", 2)).to eq((20..24).map { |n| format("Producto %02d", n) })
    end

    it "shows no pagination controls when every record fits on one page" do
      create_list(:default_product_quantity, 3)

      get default_product_quantities_path

      expect(frame_rows("default_product_quantities").size).to eq(3)
      expect(pagination_nav("default_product_quantities")).to be_nil
    end
  end

  describe "GET /default_product_quantities/new" do
    let(:zone) { create(:zone) }
    let(:route) { create(:route, zone: zone, name: "Ruta 1") }

    def panel
      response.parsed_body.at_css("turbo-frame#default_product_quantity_route_panel")
    end

    it "renders the create form and a choose-a-route prompt when no route is chosen" do
      get new_default_product_quantity_path

      expect(response).to have_http_status(:ok)
      form = response.parsed_body.at_css("form#default_product_quantity_form")
      expect(form.at_css("input[type=submit]")["value"]).to eq("Crear")
      expect(form.at_css("select[name='zone_id']")["data-action"])
        .to include("client-zone-filter#reload", "client-panel-filter#clear")
      route_select = form.at_css("turbo-frame#route_select select[name='default_product_quantity[route_id]']")
      expect(route_select["data-action"]).to include("client-panel-filter#reload")
      expect(form.at_css("input[name='default_product_quantity[quantity]']")["min"]).to eq("1")
      expect(response.parsed_body.at_css("[data-client-panel-filter-param-value='route_id']")).not_to be_nil
      expect(panel.text).to include(I18n.t("default_product_quantities.route_panel.choose_route"))
    end

    it "offers only the chosen zone's routes" do
      route
      create(:route, zone: create(:zone), name: "Ruta Lejana")

      get new_default_product_quantity_path(zone_id: zone.id)

      options = response.parsed_body.css("select[name='default_product_quantity[route_id]'] option").map(&:text)
      expect(options).to eq([I18n.t("default_product_quantities.form.route_placeholder"), "Ruta 1"])
    end

    it "lists the chosen route's defaults by product, with edit and delete controls, excluding other routes" do
      queso = create(:default_product_quantity, route: route, quantity: 20, product: create(:product, name: "Queso"))
      create(:default_product_quantity, route: route, quantity: 5, product: create(:product, name: "Crema"))
      create(:default_product_quantity, route: create(:route, zone: zone), product: create(:product, name: "Suero"))

      get new_default_product_quantity_path(route_id: route.id)

      expect(panel.at_css("h2").text).to include("Ruta 1")
      items = panel.css("[id^='default_product_quantity_']").map do |item|
        item.css("span").map { |s| s.text.strip }.first(2)
      end
      expect(items).to eq([%w[Crema 5], %w[Queso 20]])
      item = panel.at_css("#default_product_quantity_#{queso.id}")
      edit = item.css("button").find { |b| b.text.strip == "Editar" }
      expect(edit["data-edit-modal-url-param"]).to eq(edit_default_product_quantity_path(queso, context: "panel"))
      expect(item.text).to include("Eliminar")
      expect(panel.text).not_to include("Suero")
    end

    it "says so when the chosen route has no defaults" do
      get new_default_product_quantity_path(route_id: route.id)

      expect(panel.text).to include(I18n.t("default_product_quantities.route_panel.empty"))
    end
  end

  describe "GET /default_product_quantities/:id/edit" do
    it "renders the modal frame with fixed zone and route and only product and quantity fields" do
      record = create(:default_product_quantity, quantity: 4)

      get edit_default_product_quantity_path(record, context: "panel")

      expect(response).to have_http_status(:ok)
      frame = response.parsed_body.at_css("turbo-frame#default_product_quantity_edit_modal")
      expect(frame.text).to include(record.zone.name, record.route.name)
      fields = frame.css("input, select").filter_map { |field| field["name"] }
      expect(fields).to include("default_product_quantity[product_id]", "default_product_quantity[quantity]")
      expect(fields).not_to include("zone_id", "default_product_quantity[route_id]")
      expect(frame.at_css("form")["action"]).to eq(default_product_quantity_path(record, context: "panel"))
      expect(frame.at_css("input[type=submit]")["value"]).to eq("Actualizar")
      expect(response.body).not_to include("<html")
    end
  end

  describe "POST /default_product_quantities" do
    let(:zone) { create(:zone) }
    let(:route) { create(:route, zone: zone) }

    def post_default(attrs, zone_id: zone.id)
      post default_product_quantities_path, params: { zone_id: zone_id, default_product_quantity: attrs },
                                            as: :turbo_stream
    end

    it "creates the record, refreshes the route's list, and resets the form keeping zone and route" do
      product = create(:product, name: "Queso")

      expect do
        post_default({ route_id: route.id, product_id: product.id, quantity: 5 })
      end.to change(DefaultProductQuantity, :count).by(1)

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      body = stream_body
      list_id = ActionView::RecordIdentifier.dom_id(route, :default_product_quantities)
      list = body.at_css("turbo-stream[action='replace'][target='#{list_id}']")
      expect(list.at_css("template").inner_html).to include("Queso")
      form = body.at_css("turbo-stream[action='replace'][target='default_product_quantity_form'] template")
      expect(form.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(zone.id.to_s)
      route_option = form.at_css("select[name='default_product_quantity[route_id]'] option[selected]")
      expect(route_option["value"]).to eq(route.id.to_s)
      expect(form.at_css("select[name='default_product_quantity[product_id]'] option[selected]")).to be_nil
      expect(form.at_css("input[name='default_product_quantity[quantity]']")["value"]).to be_nil
    end

    it "creates several records for the same route in a row" do
      2.times { post_default({ route_id: route.id, product_id: create(:product).id, quantity: 3 }) }

      expect(route.default_product_quantities.count).to eq(2)
    end

    it "re-renders the form with an error for a route+product that already has a default" do
      existing = create(:default_product_quantity)

      expect do
        post_default({ route_id: existing.route_id, product_id: existing.product_id, quantity: 3 },
                     zone_id: existing.route.zone_id)
      end.not_to change(DefaultProductQuantity, :count)

      expect(response).to have_http_status(:unprocessable_content)
      form = stream_body.at_css("turbo-stream[target='default_product_quantity_form'] template")
      expect(form.at_css("select[name='default_product_quantity[route_id]'] option[selected]")["value"])
        .to eq(existing.route_id.to_s)
    end

    it "re-renders the form with a zero, negative or non-integer quantity" do
      ["0", "-1", "2.5"].each do |quantity|
        expect do
          post_default({ route_id: route.id, product_id: create(:product).id, quantity: quantity })
        end.not_to change(DefaultProductQuantity, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "PATCH /default_product_quantities/:id" do
    it "updates product and quantity and streams the table row" do
      record = create(:default_product_quantity, quantity: 2)
      product = create(:product, name: "Mantequilla")

      patch default_product_quantity_path(record, context: "table"),
            params: { default_product_quantity: { product_id: product.id, quantity: 9 } }, as: :turbo_stream

      expect(record.reload).to have_attributes(quantity: 9, product_id: product.id)
      stream = stream_body.at_css("turbo-stream[action='replace'][target='default_product_quantity_#{record.id}']")
      expect(stream.at_css("template tr")).not_to be_nil
      expect(stream.text).to include("Mantequilla")
    end

    it "streams the panel item when edited from the panel" do
      record = create(:default_product_quantity, quantity: 2)

      patch default_product_quantity_path(record, context: "panel"),
            params: { default_product_quantity: { quantity: 3 } }, as: :turbo_stream

      stream = stream_body.at_css("turbo-stream[target='default_product_quantity_#{record.id}'] template")
      expect(stream.at_css("tr")).to be_nil
      expect(stream.at_css("div#default_product_quantity_#{record.id}")).not_to be_nil
    end

    it "ignores attempts to change the route" do
      record = create(:default_product_quantity)
      other_route = create(:route)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: { route_id: other_route.id, quantity: 4 }
      }, as: :turbo_stream

      expect(record.reload).to have_attributes(route_id: record.route_id, quantity: 4)
    end

    it "keeps the modal open with an error when the product is already used by the same route" do
      record = create(:default_product_quantity, quantity: 1)
      other = create(:default_product_quantity, route: record.route)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: { product_id: other.product_id }
      }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(stream_body.at_css("turbo-frame#default_product_quantity_edit_modal")).not_to be_nil
      expect(record.reload.product_id).not_to eq(other.product_id)
    end

    it "keeps the modal open with an error for a quantity of zero" do
      record = create(:default_product_quantity, quantity: 4)

      patch default_product_quantity_path(record), params: { default_product_quantity: { quantity: 0 } },
                                                   as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(record.reload.quantity).to eq(4)
    end
  end

  describe "DELETE /default_product_quantities/:id" do
    it "removes the record's row with a turbo stream" do
      record = create(:default_product_quantity)

      expect do
        delete default_product_quantity_path(record), as: :turbo_stream
      end.to change(DefaultProductQuantity, :count).by(-1)

      expect(stream_body.at_css("turbo-stream[action='remove'][target='default_product_quantity_#{record.id}']"))
        .not_to be_nil
    end

    it "still redirects with a notice for a plain HTML request" do
      record = create(:default_product_quantity)

      delete default_product_quantity_path(record)

      expect(response).to redirect_to(default_product_quantities_path)
      expect(flash[:notice]).to be_present
    end
  end
end
