require "rails_helper"

RSpec.describe "DailyProductOrders", type: :request do
  def batch_rows
    response.parsed_body.css("tbody tr").reject { |row| row.at_css("td[colspan]") }
  end

  describe "GET /daily_product_orders" do
    it "renders the zone and route filters with a Generar button and lists one row per day+route" do
      zone = create(:zone, name: "Zona Norte")
      route = create(:route, zone: zone, name: "Ruta Uno")
      create(:daily_product_order, zone: zone, route: route, day: Date.current)
      create(:daily_product_order, zone: zone, route: route, day: Date.current)

      get daily_product_orders_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Generar")
      expect(response.parsed_body.at_css("turbo-frame#route_select select[name='route_id']")).not_to be_nil
      expect(batch_rows.size).to eq(1)
      cells = batch_rows.first.css("td").map { |td| td.text.strip }
      expect(cells[0..2]).to eq([Date.current.strftime("%d/%m/%Y"), "Zona Norte", "Ruta Uno"])
    end

    it "offers only the selected zone's routes inside the route frame" do
      zone = create(:zone)
      create(:route, zone: zone, name: "Ruta Propia")
      create(:route, zone: create(:zone), name: "Ruta Ajena")

      get daily_product_orders_path(zone_id: zone.id)

      options = response.parsed_body.css("turbo-frame#route_select option").map { |o| o.text.strip }
      expect(options).to include("Ruta Propia")
      expect(options).not_to include("Ruta Ajena")
      expect(response.parsed_body.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(zone.id.to_s)
    end

    it "offers no routes until a zone is selected" do
      create(:route, name: "Ruta Cualquiera")

      get daily_product_orders_path

      options = response.parsed_body.css("turbo-frame#route_select option").map { |o| o.text.strip }
      expect(options).not_to include("Ruta Cualquiera")
    end

    it "shows a Descargar consolidado control for each batch pointing at its route+day URL" do
      order = create(:daily_product_order, day: Date.current)

      get daily_product_orders_path

      link = response.parsed_body.css("a").find { |a| a.text.strip == "Descargar consolidado" }
      expect(link).not_to be_nil
      query = Rack::Utils.parse_query(URI.parse(link["href"]).query)
      expect(query["route_id"].to_i).to eq(order.route_id)
      expect(query["day"]).to eq(order.day.iso8601)
      expect(query).not_to have_key("zone_id")
    end

    it "lists a separate row for each route of the same zone generated on the same day" do
      zone = create(:zone)
      create(:daily_product_order, zone: zone, route: create(:route, zone: zone), day: Date.current)
      create(:daily_product_order, zone: zone, route: create(:route, zone: zone), day: Date.current)

      get daily_product_orders_path

      expect(batch_rows.size).to eq(2)
    end

    it "lists batches newest first" do
      create(:daily_product_order, route: create(:route, name: "Ruta Hoy"), day: Date.current)
      create(:daily_product_order, route: create(:route, name: "Ruta Ayer"), day: Date.current - 1,
                                   created_at: 1.day.ago)

      get daily_product_orders_path

      expect(batch_rows.map { |row| row.css("td")[2].text.strip }).to eq(["Ruta Hoy", "Ruta Ayer"])
    end

    context "with more batches than fit on one page" do
      before do
        route = create(:route)
        25.times do |n|
          create(:daily_product_order, route: route, zone: route.zone, day: Date.current - n, created_at: n.days.ago)
        end
      end

      it "shows the 20 most recent batches with pagination controls" do
        get daily_product_orders_path

        expect(batch_rows.size).to eq(20)
        expect(batch_rows.first.css("td")[0].text.strip).to eq(Date.current.strftime("%d/%m/%Y"))
        expect(pagination_nav("daily_product_orders")).not_to be_nil
      end

      it "shows the remaining batches on the next page" do
        get daily_product_orders_path(page: 2)

        expect(batch_rows.size).to eq(5)
        expect(batch_rows.last.css("td")[0].text.strip).to eq((Date.current - 24).strftime("%d/%m/%Y"))
      end
    end

    it "shows no pagination controls when every batch fits on one page" do
      route = create(:route)
      3.times do |n|
        create(:daily_product_order, route: route, zone: route.zone, day: Date.current - n, created_at: n.days.ago)
      end

      get daily_product_orders_path

      expect(batch_rows.size).to eq(3)
      expect(pagination_nav("daily_product_orders")).to be_nil
    end
  end

  describe "GET /daily_product_orders ordering and table filters" do
    let(:bosa) { create(:zone, name: "Bosa") }
    let(:soacha) { create(:zone, name: "Soacha") }

    def generate(route)
      client = create(:client, zone: route.zone)
      create(:route_stop, route: route, client: client)
      create(:default_product_quantity, zone: route.zone, client: client, quantity: 2)
      DailyProductOrderGeneration.new(route: route).call
    end

    def listed_routes
      frame_column("daily_product_orders", 2)
    end

    it "has no in-page title and a separate table filter section below the generation form" do
      get daily_product_orders_path

      body = response.parsed_body
      expect(body.at_css("h1")).to be_nil
      section = body.at_css("section")
      expect(section.at_css("h2").text.strip).to eq("Filtrar tabla")
      form = section.at_css("form[method='get'][data-turbo-frame='daily_product_orders']")
      expect(form["data-client-zone-filter-param-value"]).to eq("filter_zone_id")
      expect(form.at_css("select[name='filter_zone_id']")).not_to be_nil
      expect(form.at_css("turbo-frame#batch_route_filter select[name='filter_route_id']")).not_to be_nil
      expect(clear_filters_link["href"]).to eq(daily_product_orders_path)
      expect(body.at_css("turbo-frame#daily_product_orders[data-turbo-action='advance']")).not_to be_nil
    end

    it "lists a just-generated batch first within the same day, and a regenerated one moves to the top" do
      ruta_a = create(:route, zone: bosa, name: "Ruta A")
      ruta_z = create(:route, zone: soacha, name: "Ruta Z")
      generate(ruta_a)
      DailyProductOrder.where(route: ruta_a).find_each { |order| order.update!(created_at: 1.hour.ago) }
      generate(ruta_z)

      get daily_product_orders_path
      expect(listed_routes).to eq(["Ruta Z", "Ruta A"])

      DailyProductOrderGeneration.new(route: ruta_a).call
      DailyProductOrder.where(route: ruta_a).find_each { |order| order.update!(created_at: 1.minute.from_now) }

      get daily_product_orders_path
      expect(listed_routes).to eq(["Ruta A", "Ruta Z"])
    end

    it "filters the table by zone and by route, ignoring a route from another zone" do
      ruta1 = create(:route, zone: bosa, name: "Ruta 1")
      ruta2 = create(:route, zone: bosa, name: "Ruta 2")
      ruta3 = create(:route, zone: soacha, name: "Ruta 3")
      [ruta1, ruta2, ruta3].each { |route| create(:daily_product_order, route: route, zone: route.zone) }

      get daily_product_orders_path(filter_zone_id: bosa.id)
      expect(listed_routes).to contain_exactly("Ruta 1", "Ruta 2")

      get daily_product_orders_path(filter_zone_id: bosa.id, filter_route_id: ruta1.id)
      expect(listed_routes).to eq(["Ruta 1"])

      get daily_product_orders_path(filter_zone_id: bosa.id, filter_route_id: ruta3.id)
      expect(listed_routes).to contain_exactly("Ruta 1", "Ruta 2")
    end

    it "keeps the table filter route choices and the generation route choices independent" do
      create(:route, zone: bosa, name: "Ruta Bosa")
      create(:route, zone: soacha, name: "Ruta Soacha")

      get daily_product_orders_path(zone_id: soacha.id, filter_zone_id: bosa.id)

      body = response.parsed_body
      table_routes = body.css("turbo-frame#batch_route_filter option").map { |o| o.text.strip }
      generation_routes = body.css("turbo-frame#route_select option").map { |o| o.text.strip }
      expect(table_routes).to eq(["Todas las rutas", "Ruta Bosa"])
      expect(generation_routes).to eq(["Selecciona una ruta", "Ruta Soacha"])
      expect(body.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(soacha.id.to_s)
      expect(body.at_css("select[name='filter_zone_id'] option[selected]")["value"]).to eq(bosa.id.to_s)
    end

    it "offers no table routes until a table zone is selected" do
      create(:route, zone: bosa, name: "Ruta Bosa")

      get daily_product_orders_path

      expect(response.parsed_body.css("turbo-frame#batch_route_filter option").map { |o| o.text.strip })
        .to eq(["Todas las rutas"])
    end

    it "shows a no-results message when the filters match no batch" do
      create(:daily_product_order, route: create(:route, zone: bosa), zone: bosa)

      get daily_product_orders_path(filter_zone_id: soacha.id)

      expect(frame_rows("daily_product_orders")).to be_empty
      expect(response.body).to include(I18n.t("daily_product_orders.index.no_results"))
    end

    it "keeps the table filters on page links" do
      route = create(:route, zone: bosa)
      25.times do |n|
        create(:daily_product_order, route: route, zone: bosa, day: Date.current - n, created_at: n.days.ago)
      end

      get daily_product_orders_path(filter_zone_id: bosa.id)

      expect(next_page_query("daily_product_orders"))
        .to include("filter_zone_id" => bosa.id.to_s, "page" => "2")
    end
  end

  describe "POST /daily_product_orders/generate" do
    it "shows an error and creates nothing when no zone is chosen" do
      expect do
        post generate_daily_product_orders_path, params: { zone_id: "", route_id: "" }
      end.not_to change(DailyProductOrder, :count)

      expect(response).to redirect_to(daily_product_orders_path)
      expect(flash[:alert]).to eq(I18n.t("daily_product_orders.generate.missing_zone"))
    end

    it "shows an error and creates nothing when no route is chosen" do
      zone = create(:zone)

      expect do
        post generate_daily_product_orders_path, params: { zone_id: zone.id, route_id: "" }
      end.not_to change(DailyProductOrder, :count)

      expect(response).to redirect_to(daily_product_orders_path)
      expect(flash[:alert]).to eq(I18n.t("daily_product_orders.generate.missing_route"))
    end

    it "rejects a route that does not belong to the chosen zone" do
      zone = create(:zone)
      other_route = create(:route)
      create(:route_stop, route: other_route)

      expect do
        post generate_daily_product_orders_path, params: { zone_id: zone.id, route_id: other_route.id }
      end.not_to change(DailyProductOrder, :count)

      expect(flash[:alert]).to eq(I18n.t("daily_product_orders.generate.missing_route"))
    end

    it "generates the route's batch and redirects with a success notice" do
      zone = create(:zone)
      route = create(:route, zone: zone)
      client = create(:client, zone: zone)
      create(:route_stop, route: route, client: client)
      create(:default_product_quantity, zone: zone, client: client, product: create(:product), quantity: 6)

      expect do
        post generate_daily_product_orders_path, params: { zone_id: zone.id, route_id: route.id }
      end.to change(DailyProductOrder, :count).by(1)

      expect(response).to redirect_to(daily_product_orders_path)
      expect(flash[:notice]).to include(zone.name, route.name)
      expect(DailyProductOrder.last).to have_attributes(quantity: 6, route_id: route.id, zone_id: zone.id)
    end
  end

  describe "GET /daily_product_orders/consolidated" do
    it "returns the route's spreadsheet with the expected filename, client, and product content" do
      zone = create(:zone, name: "Zona Sur")
      route = create(:route, zone: zone, name: "Ruta 3")
      client = create(:client, zone: zone, name: "Tienda Test")
      create(:route_stop, route: route, client: client)
      product = create(:product, name: "Queso")
      order = create(:daily_product_order, zone: zone, route: route, client: client, product: product,
                                           day: Date.current, quantity: 4)

      get consolidated_daily_product_orders_path(route_id: route.id, day: order.day.iso8601)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
      expect(response.headers["Content-Disposition"])
        .to include("consolidado_zona-sur_ruta-3_#{order.day.iso8601}.xlsx")

      workbook_rows = extract_rows(response.body)
      expect(workbook_rows.flatten).to include("Tienda Test", "Queso")
    end
  end

  def extract_rows(xlsx_binary)
    require "zip"
    require "rexml/document"
    rows = []
    Zip::File.open_buffer(xlsx_binary) do |zip|
      entry = zip.glob("xl/worksheets/sheet1.xml").first
      doc = REXML::Document.new(entry.get_input_stream.read)
      doc.root.elements.each("sheetData/row") { |row| rows << row_values(row) }
    end
    rows
  end

  def row_values(row)
    row.elements.map { |cell| cell.elements["is/t"]&.text || cell.elements["v"]&.text }
  end
end
