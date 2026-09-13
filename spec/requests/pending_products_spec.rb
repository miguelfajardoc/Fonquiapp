require "rails_helper"

RSpec.describe "PendingProducts", type: :request do
  describe "GET /pending_products" do
    it "lists every record's date, client, product, quantity, and state, with edit/delete/toggle controls" do
      client = create(:client, name: "Tienda Norte")
      product = create(:product, name: "Agua 500ml")
      record = create(:pending_product, client: client, zone: client.zone, product: product, quantity: 4)

      get pending_products_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(client.name)
      expect(response.body).to include(product.name)
      expect(response.body).to include("4")
      expect(response.body).to include("Pendiente")
      expect(response.body).to include("Crear Pendiente")
      expect(response.body).to include(edit_pending_product_path(record, context: "table"))
      expect(response.body).to include(toggle_state_pending_product_path(record, context: "table"))
      expect(response.body).to include("Eliminar")
    end

    it "renders exactly one confirmation dialog and one edit modal regardless of record count" do
      create_list(:pending_product, 3)

      get pending_products_path

      expect(response.body.scan("<dialog").count).to eq(2)
    end

    it "does not render a toggle control for a canceled record" do
      record = create(:pending_product, state: :canceled)

      get pending_products_path

      expect(response.body).not_to include(toggle_state_pending_product_path(record, context: "table"))
    end
  end

  describe "GET /pending_products/new" do
    it "renders the creation form with a Crear submit button" do
      get new_pending_product_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Crear"')
    end

    it "shows a choose-a-client message when no client is selected" do
      get new_pending_product_path

      expect(response.body).to include("Selecciona un cliente")
    end

    it "shows the chosen client's pending products when client_id is given" do
      client = create(:client, name: "Tienda Sur")
      other_client = create(:client, name: "Tienda Norte")
      product = create(:product, name: "Gaseosa 1L")
      matching = create(:pending_product, client: client, zone: client.zone, product: product, quantity: 2)
      create(:pending_product, client: other_client, zone: other_client.zone)

      get new_pending_product_path(client_id: client.id)

      expect(response.body).to include("Pendientes Cliente #{client.name}")
      expect(response.body).to include(product.name)
      expect(response.body).to include(dom_id_for(matching))
    end
  end

  describe "GET /pending_products/client_options" do
    it "returns matching clients across all zones" do
      zone_a = create(:zone)
      zone_b = create(:zone)
      client_in_a = create(:client, zone: zone_a, name: "Tienda A")
      client_in_b = create(:client, zone: zone_b, name: "Tienda B")

      get client_options_pending_products_path, as: :turbo_stream

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(client_in_a.name)
      expect(response.body).to include(client_in_b.name)
    end

    it "narrows by the search query" do
      matching = create(:client, name: "Tienda Norte")
      other = create(:client, name: "Tienda Sur")

      get client_options_pending_products_path(q: "Norte"), as: :turbo_stream

      expect(response.body).to include(matching.name)
      expect(response.body).not_to include(other.name)
    end
  end

  describe "POST /pending_products" do
    it "creates a pending record for the client's zone, updating the client panel and form via turbo_stream" do
      client = create(:client)
      product = create(:product)

      expect do
        post pending_products_path, params: {
          pending_product: { client_id: client.id, product_id: product.id, quantity: 3 }
        }, as: :turbo_stream
      end.to change(PendingProduct, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)

      record = PendingProduct.last
      expect(record.state).to eq("pending")
      expect(record.zone_id).to eq(client.zone_id)
      expect(response.body).to include("turbo-stream")
      expect(response.body).to include(dom_id_for(client, :pending_products))
      expect(response.body).to include("pending_product_form")
    end

    it "does not create a record with an invalid quantity, re-rendering the form with an error" do
      client = create(:client)
      product = create(:product)

      expect do
        post pending_products_path, params: {
          pending_product: { client_id: client.id, product_id: product.id, quantity: 0 }
        }, as: :turbo_stream
      end.not_to change(PendingProduct, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("pending_product_form")
    end
  end

  describe "GET /pending_products/:id/edit" do
    it "renders the edit form inside the modal's turbo frame with an Actualizar button" do
      record = create(:pending_product)

      get edit_pending_product_path(record, context: "table")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('value="Actualizar"')
      expect(response.body).to include("pending_product_edit_modal")
    end
  end

  describe "PATCH /pending_products/:id" do
    it "updates the record and replaces its row via turbo_stream, for both the table and panel contexts" do
      record = create(:pending_product, quantity: 2)

      patch pending_product_path(record, context: "table"), params: {
        pending_product: { quantity: 9 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(dom_id_for(record))
      expect(record.reload.quantity).to eq(9)
    end

    it "does not update with an invalid quantity, re-rendering the edit frame with a validation error" do
      record = create(:pending_product, quantity: 5)

      patch pending_product_path(record, context: "panel"), params: {
        pending_product: { quantity: -1 }
      }, as: :turbo_stream

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("pending_product_edit_modal")
      expect(record.reload.quantity).to eq(5)
    end
  end

  describe "PATCH /pending_products/:id/toggle_state" do
    it "toggles a pending record to delivered" do
      record = create(:pending_product, state: :pending)

      patch toggle_state_pending_product_path(record, context: "table"), as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(dom_id_for(record))
      expect(record.reload.state).to eq("delivered")
    end

    it "toggles a delivered record back to pending" do
      record = create(:pending_product, state: :delivered)

      patch toggle_state_pending_product_path(record, context: "table"), as: :turbo_stream

      expect(record.reload.state).to eq("pending")
    end
  end

  describe "DELETE /pending_products/:id" do
    it "removes the record via turbo_stream" do
      record = create(:pending_product)

      expect do
        delete pending_product_path(record), as: :turbo_stream
      end.to change(PendingProduct, :count).by(-1)

      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
      expect(response.body).to include(dom_id_for(record))
    end

    it "redirects to the index with a notice for a plain html request" do
      record = create(:pending_product)

      delete pending_product_path(record)

      expect(response).to redirect_to(pending_products_path)
      expect(flash[:notice]).to be_present
    end
  end

  def dom_id_for(record, prefix = nil)
    ActionView::RecordIdentifier.dom_id(record, prefix)
  end
end
