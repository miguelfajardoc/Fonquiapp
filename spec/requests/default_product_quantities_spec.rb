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

    it "renders exactly one confirmation dialog regardless of record count" do
      create_list(:default_product_quantity, 3)

      get default_product_quantities_path

      expect(response.body.scan("<dialog").count).to eq(1)
      expect(response.body).to include("¿Estás seguro")
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

    it "makes each row's Editar link open the edit page outside the table frame" do
      record = default_for("Tienda Norte", zone)

      get default_product_quantities_path(zone_id: zone.id)

      link = response.parsed_body.css("turbo-frame#default_product_quantities a").find { |a| a.text.strip == "Editar" }
      expect(link["href"]).to eq(edit_default_product_quantity_path(record))
      expect(link["data-turbo-frame"]).to eq("_top")
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
    it "renders the form with a Crear submit button" do
      get new_default_product_quantity_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Crear"')
      expect(response.body).not_to include('value="Actualizar"')
    end
  end

  describe "GET /default_product_quantities/:id/edit" do
    it "renders the form with an Actualizar submit button" do
      record = create(:default_product_quantity)

      get edit_default_product_quantity_path(record)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Actualizar"')
      expect(response.body).not_to include('value="Crear"')
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
    it "creates a record with a valid, unused combination" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)

      expect do
        post default_product_quantities_path, params: {
          default_product_quantity: { zone_id: zone.id, client_id: client.id, product_id: product.id, quantity: 5 }
        }
      end.to change(DefaultProductQuantity, :count).by(1)

      expect(response).to redirect_to(default_product_quantities_path)
    end

    it "re-renders the form for a combination that already has a default" do
      existing = create(:default_product_quantity)

      expect do
        post default_product_quantities_path, params: {
          default_product_quantity: {
            zone_id: existing.zone_id, client_id: existing.client_id,
            product_id: existing.product_id, quantity: 3
          }
        }
      end.not_to change(DefaultProductQuantity, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the form with a negative quantity" do
      zone = create(:zone)
      client = create(:client, zone: zone)
      product = create(:product)

      expect do
        post default_product_quantities_path, params: {
          default_product_quantity: { zone_id: zone.id, client_id: client.id, product_id: product.id, quantity: -1 }
        }
      end.not_to change(DefaultProductQuantity, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /default_product_quantities/:id" do
    it "updates a record with a valid quantity" do
      record = create(:default_product_quantity, quantity: 2)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: { quantity: 9 }
      }

      expect(response).to redirect_to(default_product_quantities_path)
      expect(record.reload.quantity).to eq(9)
    end

    it "does not update into a combination already used by another record" do
      other = create(:default_product_quantity)
      record = create(:default_product_quantity, quantity: 1)

      patch default_product_quantity_path(record), params: {
        default_product_quantity: {
          zone_id: other.zone_id, client_id: other.client_id, product_id: other.product_id
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(record.reload.quantity).to eq(1)
    end
  end

  describe "DELETE /default_product_quantities/:id" do
    it "deletes the record" do
      record = create(:default_product_quantity)

      expect do
        delete default_product_quantity_path(record)
      end.to change(DefaultProductQuantity, :count).by(-1)

      expect(response).to redirect_to(default_product_quantities_path)
      expect(flash[:notice]).to be_present
    end
  end
end
