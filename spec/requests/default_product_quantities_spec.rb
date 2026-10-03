require "rails_helper"

RSpec.describe "DefaultProductQuantities", type: :request do
  describe "GET /default_product_quantities" do
    it "lists every existing record with client, product, quantity, and per-row edit/delete controls" do
      zone = create(:zone)
      client = create(:client, zone: zone, name: "Tienda Norte")
      product = create(:product, name: "Agua 500ml")
      record = create(:default_product_quantity, zone: zone, client: client, product: product, quantity: 7)

      get default_product_quantities_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(product.name)
      expect(response.body).to include("7")
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
  end

  describe "GET /default_product_quantities with filters and pagination" do
    let(:zone) { create(:zone, name: "Bosa") }
    let(:other_zone) { create(:zone, name: "Soacha") }

    def default_for(client_name, in_zone)
      create(:default_product_quantity, zone: in_zone, client: create(:client, name: client_name, zone: in_zone))
    end

    it "has no in-page title and puts the filters, clear link, and create button on one row" do
      get default_product_quantities_path

      body = response.parsed_body
      expect(body.at_css("h1")).to be_nil
      form = body.at_css("form[method='get'][data-turbo-frame='default_product_quantities']")
      expect(form.at_css("input[name='client_name']")).not_to be_nil
      expect(form.at_css("select[name='zone_id']")).not_to be_nil
      expect(form.parent.css("> a").map { |a| a.text.strip }).to include("Crear default")
      expect(clear_filters_link["href"]).to eq(default_product_quantities_path)
      expect(clear_filters_link["data-turbo-frame"]).to eq("_top")
    end

    it "shows a Zona column after Cliente" do
      default_for("Tienda Norte", zone)

      get default_product_quantities_path

      headers = frame_headers("default_product_quantities")
      expect(headers[headers.index("Cliente") + 1]).to eq("Zona")
      expect(frame_column("default_product_quantities", 1)).to eq(["Bosa"])
    end

    it "filters by client name ignoring accents, by zone, and by both combined" do
      default_for("Tienda San José", zone)
      default_for("Salsamentaria", zone)
      default_for("Tienda Centro", other_zone)

      get default_product_quantities_path(client_name: "jose")
      expect(frame_column("default_product_quantities", 0)).to eq(["Tienda San José"])

      get default_product_quantities_path(zone_id: zone.id)
      expect(frame_column("default_product_quantities", 0)).to eq(["Salsamentaria", "Tienda San José"])

      get default_product_quantities_path(client_name: "tienda", zone_id: zone.id)
      expect(frame_column("default_product_quantities", 0)).to eq(["Tienda San José"])
      body = response.parsed_body
      expect(body.at_css("input[name='client_name']")["value"]).to eq("tienda")
      expect(body.at_css("select[name='zone_id'] option[selected]")["value"]).to eq(zone.id.to_s)
    end

    it "renders each row with its dom id and an Editar button that opens the edit modal" do
      record = default_for("Tienda Norte", zone)

      get default_product_quantities_path(zone_id: zone.id)

      frame = response.parsed_body.at_css("turbo-frame#default_product_quantities")
      row = frame.at_css("tr#default_product_quantity_#{record.id}")
      button = row.css("button").find { |b| b.text.strip == "Editar" }
      expect(button["data-action"]).to eq("edit-modal#open")
      expect(button["data-edit-modal-url-param"]).to eq(edit_default_product_quantity_path(record, context: "table"))
      expect(response.parsed_body.at_css("[data-controller~='edit-modal']")).not_to be_nil
    end

    it "shows a message when no record matches" do
      default_for("Tienda", zone)

      get default_product_quantities_path(client_name: "zzz")

      expect(frame_rows("default_product_quantities")).to be_empty
      expect(response.body).to include(I18n.t("default_product_quantities.index.no_results"))
    end

    it "paginates 20 per page, keeping the zone filter on page links" do
      25.times { |n| default_for(format("Bosa %02d", n), zone) }
      5.times { |n| default_for(format("Otra %02d", n), other_zone) }

      get default_product_quantities_path(zone_id: zone.id)

      expect(frame_rows("default_product_quantities").size).to eq(20)
      expect(next_page_query("default_product_quantities")).to include("zone_id" => zone.id.to_s, "page" => "2")

      get default_product_quantities_path(zone_id: zone.id, page: 2)

      expect(frame_column("default_product_quantities", 0)).to eq((20..24).map { |n| format("Bosa %02d", n) })
    end

    it "shows no pagination controls when every record fits on one page" do
      3.times { |n| default_for("Cliente #{n}", zone) }

      get default_product_quantities_path

      expect(frame_rows("default_product_quantities").size).to eq(3)
      expect(pagination_nav("default_product_quantities")).to be_nil
    end
  end

  describe "GET /default_product_quantities/new" do
    let(:zone) { create(:zone) }
    let(:client) { create(:client, zone: zone, name: "Tienda Norte") }

    def panel
      response.parsed_body.at_css("turbo-frame#default_product_quantity_client_panel")
    end

    it "renders the create form and a choose-a-client prompt when no client is chosen" do
      get new_default_product_quantity_path

      expect(response).to have_http_status(:ok)
      form = response.parsed_body.at_css("form#default_product_quantity_form")
      expect(form.at_css("input[type=submit]")["value"]).to eq("Crear")
      expect(form.at_css("select[name='default_product_quantity[zone_id]']")["data-action"])
        .to include("client-panel-filter#reload")
      expect(panel.text).to include(I18n.t("default_product_quantities.client_panel.choose_client"))
    end

    it "lists the chosen client's defaults by product, with edit and delete controls, excluding other clients" do
      queso = create(:default_product_quantity, zone: zone, client: client, quantity: 5,
                                                product: create(:product, name: "Queso"))
      create(:default_product_quantity, zone: zone, client: client, quantity: 2,
                                        product: create(:product, name: "Crema"))
      create(:default_product_quantity, zone: zone, product: create(:product, name: "Suero"),
                                        client: create(:client, zone: zone))

      get new_default_product_quantity_path(client_id: client.id)

      expect(panel.at_css("h2").text).to include("Tienda Norte")
      items = panel.css("[id^='default_product_quantity_']").map do |item|
        item.css("span").map do |s|
          s.text.strip
        end.first(2)
      end
      expect(items).to eq([%w[Crema 2], %w[Queso 5]])
      item = panel.at_css("#default_product_quantity_#{queso.id}")
      edit = item.css("button").find { |b| b.text.strip == "Editar" }
      expect(edit["data-edit-modal-url-param"]).to eq(edit_default_product_quantity_path(queso, context: "panel"))
      expect(item.text).to include("Eliminar")
      expect(panel.text).not_to include("Suero")
    end

    it "says so when the chosen client has no defaults" do
      get new_default_product_quantity_path(client_id: client.id)

      expect(panel.text).to include(I18n.t("default_product_quantities.client_panel.empty"))
    end
  end

  describe "GET /default_product_quantities/:id/edit" do
    it "renders the modal frame with fixed zone and client and only product and quantity fields" do
      record = create(:default_product_quantity, quantity: 4)

      get edit_default_product_quantity_path(record, context: "panel")

      expect(response).to have_http_status(:ok)
      frame = response.parsed_body.at_css("turbo-frame#default_product_quantity_edit_modal")
      expect(frame.text).to include(record.zone.name, record.client.name)
      fields = frame.css("input, select").filter_map { |field| field["name"] }
      expect(fields).to include("default_product_quantity[product_id]", "default_product_quantity[quantity]")
      expect(fields).not_to include("default_product_quantity[zone_id]", "default_product_quantity[client_id]")
      expect(frame.at_css("form")["action"]).to eq(default_product_quantity_path(record, context: "panel"))
      expect(frame.at_css("input[type=submit]")["value"]).to eq("Actualizar")
      expect(response.body).not_to include("<html")
    end
  end

  describe "GET /default_product_quantities/client_options" do
    it "returns only clients belonging to the requested zone" do
      zone_a = create(:zone)
      zone_b = create(:zone)
      client_in_a = create(:client, zone: zone_a, name: "Tienda A")
      client_in_b = create(:client, zone: zone_b, name: "Tienda B")

      get client_options_default_product_quantities_path(zone_id: zone_a.id), as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(client_in_a.name)
      expect(response.body).not_to include(client_in_b.name)
    end

    it "further narrows by the search query" do
      zone = create(:zone)
      matching = create(:client, zone: zone, name: "Tienda Norte")
      other = create(:client, zone: zone, name: "Tienda Sur")

      get client_options_default_product_quantities_path(zone_id: zone.id, q: "Norte"), as: :turbo_stream

      expect(response.body).to include(matching.name)
      expect(response.body).not_to include(other.name)
    end
  end

  describe "POST /default_product_quantities" do
    let(:zone) { create(:zone) }
    let(:client) { create(:client, zone: zone) }

    def post_default(attrs)
      post default_product_quantities_path, params: { default_product_quantity: attrs }, as: :turbo_stream
    end

    it "creates the record, refreshes the client's list, and resets the form keeping zone and client" do
      product = create(:product, name: "Queso")

      expect do
        post_default(zone_id: zone.id, client_id: client.id, product_id: product.id, quantity: 5)
      end.to change(DefaultProductQuantity, :count).by(1)

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      body = stream_body
      list_id = ActionView::RecordIdentifier.dom_id(client, :default_product_quantities)
      list = body.at_css("turbo-stream[action='replace'][target='#{list_id}']")
      expect(list.at_css("template").inner_html).to include("Queso")
      form = body.at_css("turbo-stream[action='replace'][target='default_product_quantity_form'] template")
      zone_option = form.at_css("select[name='default_product_quantity[zone_id]'] option[selected]")
      expect(zone_option["value"]).to eq(zone.id.to_s)
      expect(form.at_css("input[name='default_product_quantity[client_id]']")["value"]).to eq(client.id.to_s)
      expect(form.at_css("input[name='default_product_quantity[quantity]']")["value"]).to be_nil
    end

    it "creates several records for the same client in a row" do
      2.times { |n| post_default(zone_id: zone.id, client_id: client.id, product_id: create(:product).id, quantity: n) }

      expect(client.default_product_quantities.count).to eq(2)
    end

    it "re-renders the form with an error for a combination that already has a default" do
      existing = create(:default_product_quantity)

      expect do
        post_default(zone_id: existing.zone_id, client_id: existing.client_id, product_id: existing.product_id,
                     quantity: 3)
      end.not_to change(DefaultProductQuantity, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(stream_body.at_css("turbo-stream[target='default_product_quantity_form']")).not_to be_nil
    end

    it "re-renders the form with a negative quantity" do
      expect do
        post_default(zone_id: zone.id, client_id: client.id, product_id: create(:product).id, quantity: -1)
      end.not_to change(DefaultProductQuantity, :count)

      expect(response).to have_http_status(:unprocessable_content)
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

    it "ignores attempts to change zone or client" do
      record = create(:default_product_quantity)
      other_zone = create(:zone)
      other_client = create(:client, zone: other_zone)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: { zone_id: other_zone.id, client_id: other_client.id, quantity: 4 }
      }, as: :turbo_stream

      expect(record.reload).to have_attributes(zone_id: record.zone_id, client_id: record.client_id, quantity: 4)
    end

    it "keeps the modal open with an error when the product is already used by the same client" do
      record = create(:default_product_quantity, quantity: 1)
      other = create(:default_product_quantity, zone: record.zone, client: record.client)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: { product_id: other.product_id }
      }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(stream_body.at_css("turbo-frame#default_product_quantity_edit_modal")).not_to be_nil
      expect(record.reload.product_id).not_to eq(other.product_id)
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
