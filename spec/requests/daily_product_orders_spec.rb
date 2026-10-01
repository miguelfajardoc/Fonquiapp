require "rails_helper"

RSpec.describe "DailyProductOrders", type: :request do
  def batch_rows
    response.parsed_body.css("tbody tr").reject { |row| row.at_css("td[colspan]") }
  end

  def pagination_nav
    response.parsed_body.at_css("nav.pagy")
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
      create(:daily_product_order, route: create(:route, name: "Ruta Ayer"), day: Date.current - 1)
      create(:daily_product_order, route: create(:route, name: "Ruta Hoy"), day: Date.current)

      get daily_product_orders_path

      expect(batch_rows.map { |row| row.css("td")[2].text.strip }).to eq(["Ruta Hoy", "Ruta Ayer"])
    end

    context "with more batches than fit on one page" do
      before do
        route = create(:route)
        25.times { |n| create(:daily_product_order, route: route, zone: route.zone, day: Date.current - n) }
      end

      it "shows the 20 most recent batches with pagination controls" do
        get daily_product_orders_path

        expect(batch_rows.size).to eq(20)
        expect(batch_rows.first.css("td")[0].text.strip).to eq(Date.current.strftime("%d/%m/%Y"))
        expect(pagination_nav).not_to be_nil
      end

      it "shows the remaining batches on the next page" do
        get daily_product_orders_path(page: 2)

        expect(batch_rows.size).to eq(5)
        expect(batch_rows.last.css("td")[0].text.strip).to eq((Date.current - 24).strftime("%d/%m/%Y"))
      end
    end

    it "shows no pagination controls when every batch fits on one page" do
      route = create(:route)
      3.times { |n| create(:daily_product_order, route: route, zone: route.zone, day: Date.current - n) }

      get daily_product_orders_path

      expect(batch_rows.size).to eq(3)
      expect(pagination_nav).to be_nil
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
