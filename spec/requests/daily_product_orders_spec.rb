require "rails_helper"

RSpec.describe "DailyProductOrders", type: :request do
  describe "GET /daily_product_orders" do
    it "renders the zone filter with a Generar button and lists existing batches, one row per day+zone" do
      zone = create(:zone, name: "Zona Norte")
      create(:daily_product_order, zone: zone, day: Date.current)
      create(:daily_product_order, zone: zone, day: Date.current)

      get daily_product_orders_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(zone.name)
      expect(response.body).to include("Generar")
      expect(response.body.scan(zone.name).count).to be >= 1
      doc = response.parsed_body
      rows = doc.css("tbody tr")
      expect(rows.size).to eq(1)
      expect(rows.first.text).to include(zone.name)
    end

    it "shows a Descargar consolidado control for each batch pointing at its consolidated URL" do
      zone = create(:zone)
      order = create(:daily_product_order, zone: zone, day: Date.current)

      get daily_product_orders_path

      link = response.parsed_body.css("a").find { |a| a.text.strip == "Descargar consolidado" }
      expect(link).not_to be_nil
      uri = URI.parse(link["href"])
      query = Rack::Utils.parse_query(uri.query)
      expect(query["zone_id"].to_i).to eq(zone.id)
      expect(query["day"]).to eq(order.day.iso8601)
    end

    it "lists a separate row for each distinct zone generated on the same day" do
      zone_a = create(:zone)
      zone_b = create(:zone)
      create(:daily_product_order, zone: zone_a, day: Date.current)
      create(:daily_product_order, zone: zone_b, day: Date.current)

      get daily_product_orders_path

      rows = response.parsed_body.css("tbody tr")
      expect(rows.size).to eq(2)
    end
  end

  describe "POST /daily_product_orders/generate" do
    it "shows an error and creates nothing when no zone is chosen" do
      expect do
        post generate_daily_product_orders_path, params: { zone_id: "" }
      end.not_to change(DailyProductOrder, :count)

      expect(response).to redirect_to(daily_product_orders_path)
      expect(flash[:alert]).to be_present
    end

    it "generates the zone's batch and redirects with a success notice" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)
      create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 6)

      expect do
        post generate_daily_product_orders_path, params: { zone_id: zone.id }
      end.to change(DailyProductOrder, :count).by(1)

      expect(response).to redirect_to(daily_product_orders_path)
      expect(flash[:notice]).to be_present
      expect(DailyProductOrder.last.quantity).to eq(6)
    end
  end

  describe "GET /daily_product_orders/consolidated" do
    it "returns the spreadsheet MIME type with the expected client and product content" do
      zone = create(:zone)
      client = create(:client, zone: zone, name: "Tienda Test")
      product = create(:product, name: "Queso")
      order = create(:daily_product_order, zone: zone, client: client, product: product, day: Date.current, quantity: 4)

      get consolidated_daily_product_orders_path(zone_id: zone.id, day: order.day.iso8601)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")

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
