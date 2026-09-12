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
